extends Node2D

const IsoMapper := preload("res://scripts/core/iso.gd")
const TILE_SIZE := IsoMapper.LOGIC_TILE_SIZE
const BlockTileScene := preload("res://scenes/visual/BlockTile.tscn")
const EnemyScene := preload("res://scenes/enemies/Enemy.tscn")
const ChestScene := preload("res://scenes/props/Chest.tscn")
const ExitScene := preload("res://scenes/props/ExitPortal.tscn")
const PickupScene := preload("res://scenes/props/WeaponPickup.tscn")

const GROUND_HEIGHT := 0
const LOW_STRUCTURE_HEIGHT := 1
const WALL_HEIGHT := 2

const THEMES := {
	"village": {
		"floor_tile": "grass",
		"accent_tile": "dirt",
		"wall_tile": "light_stone"
	},
	"forest": {
		"floor_tile": "grass",
		"accent_tile": "dirt",
		"wall_tile": "foliage"
	},
	"cave": {
		"floor_tile": "dark_stone",
		"accent_tile": "dirt",
		"wall_tile": "dark_stone"
	},
	"prison": {
		"floor_tile": "dark_stone",
		"accent_tile": "light_stone",
		"wall_tile": "light_stone"
	},
	"temple": {
		"floor_tile": "temple_stone",
		"accent_tile": "light_stone",
		"wall_tile": "temple_stone"
	},
	"abyss": {
		"floor_tile": "cracked",
		"accent_tile": "lava",
		"wall_tile": "dark_stone"
	}
}

var game: Node = null
var level_data: Dictionary = {}
var blocked_rects: Array = []
var wall_rects: Array = []
var accent_rects: Array = []
var material_rects: Array = []
var height_one_rects: Array = []
var height_two_rects: Array = []
var remaining_enemies: int = 0
var exit_portal: Area2D = null
var active: bool = true
var is_final_level: bool = false
var render_origin: Vector2 = Vector2.ZERO
var engaged_enemy_count: int = 0
var entity_layer: Node2D = null

@onready var ground_layer: Node2D = $GroundLayer
@onready var structure_top_layer: Node2D = $StructureTopLayer
@onready var collision_root: Node2D = $Collision
@onready var props_root: Node2D = $Props
@onready var pickups_root: Node2D = $Pickups
@onready var occlusion_layer: Node2D = $OcclusionLayer


func setup(game_ref: Node, data: Dictionary, current_level_index: int, total_levels: int) -> void:
	game = game_ref
	level_data = data.duplicate(true)
	is_final_level = current_level_index >= total_levels - 1
	render_origin = IsoMapper.level_render_origin(level_data.get("size", Vector2i(32, 32)))
	wall_rects = level_data.get("wall_rects", [])
	accent_rects = level_data.get("accent_rects", [])
	material_rects = level_data.get("material_rects", [])
	height_one_rects = level_data.get("height_one_rects", [])
	height_two_rects = level_data.get("height_two_rects", wall_rects)
	blocked_rects = wall_rects + level_data.get("collision_height_one_rects", height_one_rects)
	entity_layer = game.get_entity_layer()
	_clear_container(ground_layer)
	_clear_container(structure_top_layer)
	_clear_container(collision_root)
	_clear_container(props_root)
	_clear_container(pickups_root)
	_clear_container(occlusion_layer)
	_build_tiles()
	_build_colliders()
	_spawn_chest(level_data.get("chest", {}))
	if not is_final_level:
		_spawn_exit(current_level_index, total_levels)
	_spawn_enemies()


func get_level_name() -> String:
	return level_data.get("name", "")


func get_start_world_position() -> Vector2:
	return tile_to_world(level_data.get("start", Vector2i.ZERO))


func get_render_origin() -> Vector2:
	return render_origin


func set_active(value: bool) -> void:
	active = value
	for child in get_tree().get_nodes_in_group("enemies"):
		if child.has_method("set_active"):
			child.set_active(value)
	for child in props_root.get_children():
		if child.has_method("set_active"):
			child.set_active(value)
	for child in pickups_root.get_children():
		if child.has_method("set_active"):
			child.set_active(value)


func spawn_pickup(tile_position: Vector2i, reward: Dictionary) -> void:
	if reward.is_empty():
		return

	var pickup: Area2D = PickupScene.instantiate()
	pickup.position = tile_to_world(tile_position)
	pickup.setup(game, reward)
	pickup.set_render_origin(render_origin)
	pickups_root.add_child(pickup)


func tile_to_world(tile: Vector2i) -> Vector2:
	return Vector2(tile.x, tile.y) * TILE_SIZE + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)


func world_to_tile(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / TILE_SIZE), floori(world_position.y / TILE_SIZE))


func _build_colliders() -> void:
	for wall_rect in blocked_rects:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(wall_rect.size.x, wall_rect.size.y) * TILE_SIZE
		shape.shape = rectangle
		body.position = Vector2(wall_rect.position) * TILE_SIZE + Vector2(wall_rect.size) * TILE_SIZE * 0.5
		body.add_child(shape)
		collision_root.add_child(body)


func _build_tiles() -> void:
	var size: Vector2i = level_data["size"]
	var theme: Dictionary = THEMES.get(level_data.get("theme", "village"), THEMES["village"])
	for y in range(size.y):
		for x in range(size.x):
			var cell := Vector2i(x, y)
			var tile_type: String = _get_tile_type(cell, theme)
			var visual_height: int = _get_tile_visual_height(cell)
			var left_face_visible_from_layer: int = _get_neighbor_structure_height(cell + Vector2i(0, 1))
			var right_face_visible_from_layer: int = _get_neighbor_structure_height(cell + Vector2i(1, 0))

			if visual_height <= GROUND_HEIGHT:
				var ground_tile: Node2D = BlockTileScene.instantiate()
				ground_tile.setup(
					tile_type,
					cell,
					render_origin,
					GROUND_HEIGHT,
					true,
					false,
					0,
					0,
					0
				)
				ground_layer.add_child(ground_tile)
				continue

			var structure_tile: Node2D = BlockTileScene.instantiate()
			structure_tile.setup(
				tile_type,
				cell,
				render_origin,
				visual_height,
				true,
				false,
				0,
				left_face_visible_from_layer,
				right_face_visible_from_layer
			)
			structure_top_layer.add_child(structure_tile)

			var occlusion_tile: Node2D = BlockTileScene.instantiate()
			occlusion_tile.setup(
				tile_type,
				cell,
				render_origin,
				visual_height,
				false,
				true,
				2,
				left_face_visible_from_layer,
				right_face_visible_from_layer
			)
			occlusion_layer.add_child(occlusion_tile)


func _spawn_chest(chest_data: Dictionary) -> void:
	if chest_data.is_empty():
		return

	var chest: Area2D = ChestScene.instantiate()
	chest.position = tile_to_world(chest_data.get("position", Vector2i.ZERO))
	chest.setup(game, chest_data.get("reward", {}))
	chest.set_render_origin(render_origin)
	props_root.add_child(chest)


func _spawn_exit(current_level_index: int, total_levels: int) -> void:
	var exit_tile: Vector2i = level_data.get("exit", Vector2i(-1, -1))
	if exit_tile.x < 0:
		return

	exit_portal = ExitScene.instantiate()
	exit_portal.position = tile_to_world(exit_tile)
	var next_index: int = current_level_index + 1
	if current_level_index >= total_levels - 1:
		next_index = -1
	exit_portal.setup(game, next_index, level_data.get("name", ""))
	exit_portal.set_render_origin(render_origin)
	props_root.add_child(exit_portal)


func _spawn_enemies() -> void:
	remaining_enemies = 0
	engaged_enemy_count = 0
	for enemy_data in level_data.get("enemies", []):
		var enemy: CharacterBody2D = EnemyScene.instantiate()
		enemy.position = tile_to_world(enemy_data.get("position", Vector2i.ZERO))
		enemy.setup(enemy_data.get("type", "zombie"), game, enemy_data)
		enemy.set_render_origin(render_origin)
		enemy.defeated.connect(_on_enemy_defeated)
		enemy.engagement_changed.connect(_on_enemy_engagement_changed)
		entity_layer.add_child(enemy)
		remaining_enemies += 1

	_update_exit_state()




func _on_enemy_engagement_changed(_enemy: Node, engaged: bool) -> void:
	if engaged:
		engaged_enemy_count += 1
	else:
		engaged_enemy_count = max(engaged_enemy_count - 1, 0)

	if game != null and game.has_method("set_combat_music_active"):
		game.set_combat_music_active(engaged_enemy_count > 0)


func _update_exit_state() -> void:
	if is_final_level or exit_portal == null:
		return

	exit_portal.set_locked(remaining_enemies > 0)


func _on_enemy_defeated(enemy_node: Node, reward: Dictionary) -> void:
	var tile: Vector2i = world_to_tile(enemy_node.global_position)
	if not reward.is_empty():
		spawn_pickup(tile, reward)
	elif randf() < 0.22:
		spawn_pickup(tile, {"type": "heal", "amount": 1, "label": "Ration"})

	remaining_enemies = max(remaining_enemies - 1, 0)
	if remaining_enemies == 0 and is_final_level:
		game.complete_demo()
		return
	_update_exit_state()


func _is_in_rects(tile: Vector2i, rects: Array) -> bool:
	for rect in rects:
		if rect.has_point(tile):
			return true
	return false


func _clear_container(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func get_entity_layer() -> Node2D:
	return entity_layer


func _get_neighbor_structure_height(cell: Vector2i) -> int:
	var level_size: Vector2i = level_data.get("size", Vector2i.ZERO)
	if cell.x < 0 or cell.y < 0 or cell.x >= level_size.x or cell.y >= level_size.y:
		return 0
	return _get_tile_visual_height(cell)


func _get_tile_type(tile: Vector2i, theme: Dictionary) -> String:
	var override_tile: String = _get_material_override(tile)
	if not override_tile.is_empty():
		return override_tile
	if _get_tile_visual_height(tile) > GROUND_HEIGHT:
		return theme["wall_tile"]
	if _is_in_rects(tile, accent_rects):
		return theme["accent_tile"]
	return theme["floor_tile"]


func _get_tile_visual_height(tile: Vector2i) -> int:
	if _is_in_rects(tile, height_two_rects):
		return WALL_HEIGHT
	if _is_in_rects(tile, height_one_rects):
		return LOW_STRUCTURE_HEIGHT
	if _is_in_rects(tile, blocked_rects):
		return WALL_HEIGHT
	return GROUND_HEIGHT


func _get_material_override(tile: Vector2i) -> String:
	for entry in material_rects:
		var tile_name: String = entry.get("tile", "")
		var rects: Array = entry.get("rects", [])
		if tile_name.is_empty():
			continue
		if _is_in_rects(tile, rects):
			return tile_name
	return ""
