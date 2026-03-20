extends Node2D

const IsoMapper := preload("res://scripts/core/iso.gd")
const TILE_SIZE := IsoMapper.LOGIC_TILE_SIZE
const BlockTileScene := preload("res://scenes/visual/BlockTile.tscn")
const EnemyScene := preload("res://scenes/enemies/Enemy.tscn")
const ChestScene := preload("res://scenes/props/Chest.tscn")
const ExitScene := preload("res://scenes/props/ExitPortal.tscn")
const PickupScene := preload("res://scenes/props/WeaponPickup.tscn")

const THEMES := {
	"village": {
		"floor_tile": "grass",
		"accent_tile": "wood",
		"wall_tile": "wood"
	},
	"forest": {
		"floor_tile": "grass",
		"accent_tile": "wood",
		"wall_tile": "wood"
	},
	"cave": {
		"floor_tile": "stone",
		"accent_tile": "stone",
		"wall_tile": "stone"
	},
	"prison": {
		"floor_tile": "stone",
		"accent_tile": "wood",
		"wall_tile": "stone"
	},
	"temple": {
		"floor_tile": "stone",
		"accent_tile": "wood",
		"wall_tile": "stone"
	},
	"abyss": {
		"floor_tile": "stone",
		"accent_tile": "wood",
		"wall_tile": "stone"
	}
}

var game: Node = null
var level_data: Dictionary = {}
var blocked_rects: Array = []
var accent_rects: Array = []
var remaining_enemies: int = 0
var exit_portal: Area2D = null
var active: bool = true
var is_final_level: bool = false
var render_origin: Vector2 = Vector2.ZERO

@onready var tiles_root: Node2D = $Tiles
@onready var collision_root: Node2D = $Collision
@onready var props_root: Node2D = $Props
@onready var enemies_root: Node2D = $Enemies
@onready var pickups_root: Node2D = $Pickups


func setup(game_ref: Node, data: Dictionary, current_level_index: int, total_levels: int) -> void:
	game = game_ref
	level_data = data.duplicate(true)
	is_final_level = current_level_index >= total_levels - 1
	render_origin = IsoMapper.level_render_origin(level_data.get("size", Vector2i(32, 32)))
	blocked_rects = level_data.get("wall_rects", [])
	accent_rects = level_data.get("accent_rects", [])
	_clear_container(tiles_root)
	_clear_container(collision_root)
	_clear_container(props_root)
	_clear_container(enemies_root)
	_clear_container(pickups_root)
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
	for child in enemies_root.get_children():
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
			var tile: Node2D = BlockTileScene.instantiate()
			tile.setup(_get_tile_type(Vector2i(x, y), theme), Vector2i(x, y), render_origin)
			tiles_root.add_child(tile)


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
	for enemy_data in level_data.get("enemies", []):
		var enemy: CharacterBody2D = EnemyScene.instantiate()
		enemy.position = tile_to_world(enemy_data.get("position", Vector2i.ZERO))
		enemy.setup(enemy_data.get("type", "zombie"), game, enemy_data)
		enemy.set_render_origin(render_origin)
		enemy.defeated.connect(_on_enemy_defeated)
		enemies_root.add_child(enemy)
		remaining_enemies += 1

	_update_exit_state()


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


func _get_tile_type(tile: Vector2i, theme: Dictionary) -> String:
	if _is_in_rects(tile, blocked_rects):
		return theme["wall_tile"]
	if _is_in_rects(tile, accent_rects):
		return theme["accent_tile"]
	return theme["floor_tile"]
