extends Node2D

const IsoMapper := preload("res://scripts/core/iso.gd")
const TILE_SIZE := IsoMapper.LOGIC_TILE_SIZE
const BlockTileScene := preload("res://scenes/visual/BlockTile.tscn")
const EnemyScene := preload("res://scenes/enemies/Enemy.tscn")
const ChestScene := preload("res://scenes/props/Chest.tscn")
const BarrelScene := preload("res://scenes/props/Barrel.tscn")
const ExitScene := preload("res://scenes/props/ExitPortal.tscn")
const PickupScene := preload("res://scenes/props/WeaponPickup.tscn")

const GROUND_HEIGHT := 0
const LOW_STRUCTURE_HEIGHT := 1
const WALL_HEIGHT := 2
const NAVIGATION_WALL_BUFFER_TILES := 1
const NAVIGATION_LOW_STRUCTURE_BUFFER_TILES := 0

const THEMES := {
	"village": {
		"floor_tile": "grass",
		"accent_tile": "dirt",
		"wall_tile": "light_stone"
	},
	"forest": {
		"floor_tile": "forest_grass",
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
var navigation_grid: AStarGrid2D = null
var blocked_tiles: Dictionary = {}
var navigation_blocked_tiles: Dictionary = {}

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
	_build_navigation_grid()
	_validate_required_paths()
	_build_tiles()
	_build_colliders()
	_spawn_chest(level_data.get("chest", {}))
	_spawn_barrels()
	_spawn_amulet(level_data.get("amulet", {}))
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


func spawn_pickup(tile_position: Vector2i, reward: Dictionary, options: Dictionary = {}) -> void:
	spawn_pickup_at_world(tile_to_world(tile_position), reward, options)


func spawn_pickup_at_world(world_position: Vector2, reward: Dictionary, options: Dictionary = {}) -> void:
	if reward.is_empty():
		return

	var pickup: Area2D = PickupScene.instantiate()
	pickups_root.add_child(pickup)
	pickup.global_position = world_position
	pickup.setup(game, reward, options)
	pickup.set_render_origin(render_origin)


func refresh_exit_state() -> void:
	_update_exit_state()


func tile_to_world(tile: Vector2i) -> Vector2:
	return Vector2(tile.x, tile.y) * TILE_SIZE + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)


func world_to_tile(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / TILE_SIZE), floori(world_position.y / TILE_SIZE))


func get_navigation_path_tiles(from_world: Vector2, to_world: Vector2, attack_distance: float = 0.0) -> Array:
	if navigation_grid == null:
		return []

	var start_tile: Vector2i = _find_nearest_navigation_tile(world_to_tile(from_world))
	if start_tile.x < 0:
		return []

	var best_path: Array = _get_best_navigation_path(start_tile, _get_navigation_goal_candidates(start_tile, to_world, attack_distance), to_world)
	if not best_path.is_empty():
		return best_path

	return _get_best_navigation_path(start_tile, _get_navigation_fallback_candidates(to_world), to_world)


func has_clear_tile_line(from_tile: Vector2i, to_tile: Vector2i) -> bool:
	for tile in _get_line_tiles(from_tile, to_tile):
		if tile == from_tile:
			continue
		if not is_tile_walkable(tile):
			return false
	return true


func is_tile_walkable(tile: Vector2i) -> bool:
	var size: Vector2i = level_data.get("size", Vector2i.ZERO)
	if tile.x < 0 or tile.y < 0 or tile.x >= size.x or tile.y >= size.y:
		return false
	return not navigation_blocked_tiles.has(_tile_key(tile))


func has_clear_collision_tile_line(from_tile: Vector2i, to_tile: Vector2i) -> bool:
	for tile in _get_line_tiles(from_tile, to_tile):
		if tile == from_tile:
			continue
		if is_tile_hard_blocked(tile):
			return false
	return true


func is_tile_hard_blocked(tile: Vector2i) -> bool:
	return blocked_tiles.has(_tile_key(tile))


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


func _build_navigation_grid() -> void:
	var size: Vector2i = level_data.get("size", Vector2i.ZERO)
	blocked_tiles.clear()
	navigation_blocked_tiles.clear()
	navigation_grid = AStarGrid2D.new()
	navigation_grid.region = Rect2i(Vector2i.ZERO, size)
	navigation_grid.cell_size = Vector2.ONE
	navigation_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation_grid.update()

	for wall_rect in wall_rects:
		_mark_rect_tiles_solid(wall_rect)
		_mark_rect_tiles_solid_expanded(wall_rect, NAVIGATION_WALL_BUFFER_TILES)

	for low_structure_rect in level_data.get("collision_height_one_rects", height_one_rects):
		_mark_rect_tiles_solid(low_structure_rect)
		_mark_rect_tiles_solid_expanded(low_structure_rect, NAVIGATION_LOW_STRUCTURE_BUFFER_TILES)


func _mark_rect_tiles_solid(blocked_rect: Rect2i) -> void:
	for y in range(blocked_rect.position.y, blocked_rect.end.y):
		for x in range(blocked_rect.position.x, blocked_rect.end.x):
			var tile := Vector2i(x, y)
			blocked_tiles[_tile_key(tile)] = true
			navigation_blocked_tiles[_tile_key(tile)] = true
			navigation_grid.set_point_solid(tile, true)


func _mark_rect_tiles_solid_expanded(blocked_rect: Rect2i, buffer_tiles: int) -> void:
	if buffer_tiles <= 0:
		return

	var size: Vector2i = level_data.get("size", Vector2i.ZERO)
	var start_x: int = maxi(blocked_rect.position.x - buffer_tiles, 0)
	var end_x: int = mini(blocked_rect.end.x + buffer_tiles, size.x)
	var start_y: int = maxi(blocked_rect.position.y - buffer_tiles, 0)
	var end_y: int = mini(blocked_rect.end.y + buffer_tiles, size.y)
	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			var tile := Vector2i(x, y)
			navigation_blocked_tiles[_tile_key(tile)] = true
			navigation_grid.set_point_solid(tile, true)


func _find_nearest_navigation_tile(tile: Vector2i) -> Vector2i:
	if is_tile_walkable(tile):
		return tile

	for radius in range(1, 7):
		for candidate in _get_ring_tiles(tile, radius):
			if not is_tile_walkable(candidate):
				continue
			return candidate
	return Vector2i(-1, -1)


func _get_navigation_goal_candidates(start_tile: Vector2i, target_world: Vector2, attack_distance: float) -> Array:
	var target_tile: Vector2i = world_to_tile(target_world)
	var candidates: Array = []
	var level_size: Vector2i = level_data.get("size", Vector2i.ZERO)
	var attack_buffer: float = TILE_SIZE * 0.9
	var strict_max_radius: int = maxi(2, ceili((maxf(attack_distance, TILE_SIZE) + attack_buffer) / TILE_SIZE) + 1)
	var relaxed_max_radius: int = maxi(level_size.x, level_size.y)

	for radius in range(0, strict_max_radius + 1):
		for candidate in _get_ring_tiles(target_tile, radius):
			if not is_tile_walkable(candidate):
				continue
			if tile_to_world(candidate).distance_to(target_world) > attack_distance + attack_buffer:
				continue
			if not has_clear_collision_tile_line(candidate, target_tile):
				continue
			candidates.append(candidate)
		if not candidates.is_empty():
			return _sort_goal_candidates(candidates, start_tile, target_world)

	for radius in range(strict_max_radius + 1, relaxed_max_radius + 1):
		for candidate in _get_ring_tiles(target_tile, radius):
			if not is_tile_walkable(candidate):
				continue
			if not has_clear_collision_tile_line(candidate, target_tile):
				continue
			candidates.append(candidate)
		if not candidates.is_empty():
			return _sort_goal_candidates(candidates, start_tile, target_world)

	return []


func _get_navigation_fallback_candidates(target_world: Vector2) -> Array:
	var size: Vector2i = level_data.get("size", Vector2i.ZERO)
	var target_tile: Vector2i = world_to_tile(target_world)
	var clear_candidates: Array = []
	var loose_candidates: Array = []
	for y in range(size.y):
		for x in range(size.x):
			var candidate := Vector2i(x, y)
			if not is_tile_walkable(candidate):
				continue
			if has_clear_collision_tile_line(candidate, target_tile):
				clear_candidates.append(candidate)
			else:
				loose_candidates.append(candidate)

	clear_candidates = _sort_goal_candidates(clear_candidates, target_tile, target_world)
	loose_candidates = _sort_goal_candidates(loose_candidates, target_tile, target_world)
	return clear_candidates + loose_candidates


func _get_best_navigation_path(start_tile: Vector2i, candidates: Array, target_world: Vector2) -> Array:
	var best_path: Array = []
	var best_score: float = INF
	for candidate in candidates:
		var path: Array = navigation_grid.get_id_path(start_tile, candidate)
		if path.is_empty():
			continue
		var score: float = float(path.size()) * 100.0 + tile_to_world(candidate).distance_to(target_world)
		if score < best_score:
			best_score = score
			best_path = path
	return best_path


func _sort_goal_candidates(candidates: Array, start_tile: Vector2i, target_world: Vector2) -> Array:
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var a_distance_to_target: float = tile_to_world(a).distance_to(target_world)
		var b_distance_to_target: float = tile_to_world(b).distance_to(target_world)
		if not is_equal_approx(a_distance_to_target, b_distance_to_target):
			return a_distance_to_target < b_distance_to_target
		return a.distance_squared_to(start_tile) < b.distance_squared_to(start_tile)
	)
	return candidates


func _get_ring_tiles(center: Vector2i, radius: int) -> Array:
	if radius <= 0:
		return [center]

	var size: Vector2i = level_data.get("size", Vector2i.ZERO)
	var tiles: Array = []
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if x < 0 or y < 0 or x >= size.x or y >= size.y:
				continue
			if maxi(absi(x - center.x), absi(y - center.y)) != radius:
				continue
			tiles.append(Vector2i(x, y))
	return tiles




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
	chest.setup(game, self, _build_chest_contents(chest_data))
	chest.set_render_origin(render_origin)
	props_root.add_child(chest)


func _spawn_barrels() -> void:
	if game == null or not game.has_method("get_barrel_loot_config"):
		return
	var loot_config: Dictionary = game.get_barrel_loot_config()
	var barrel_count: int = int(loot_config.get("count", 0))
	if barrel_count <= 0:
		return
	var barrel_tiles: Array = _select_barrel_tiles(barrel_count)
	for tile in barrel_tiles:
		var barrel: Area2D = BarrelScene.instantiate()
		barrel.position = tile_to_world(tile)
		barrel.setup(game, self, _build_barrel_contents(loot_config))
		barrel.set_render_origin(render_origin)
		props_root.add_child(barrel)


func _spawn_exit(current_level_index: int, total_levels: int) -> void:
	var exit_tile: Vector2i = level_data.get("exit", Vector2i(-1, -1))
	if exit_tile.x < 0:
		return

	exit_portal = ExitScene.instantiate()
	exit_portal.position = tile_to_world(exit_tile)
	var target_level_id: String = String(level_data.get("next_level_id", ""))
	if current_level_index >= total_levels - 1:
		target_level_id = ""
	exit_portal.setup(game, target_level_id, level_data.get("name", ""))
	exit_portal.set_render_origin(render_origin)
	props_root.add_child(exit_portal)
	_update_exit_state()


func _spawn_amulet(amulet_data: Dictionary) -> void:
	if amulet_data.is_empty():
		return

	var pickup: Area2D = PickupScene.instantiate()
	pickup.position = tile_to_world(amulet_data.get("position", Vector2i.ZERO))
	pickup.setup(game, {
		"type": "amulet",
		"id": amulet_data.get("id", "amulet"),
		"label": amulet_data.get("label", "Amulett erhalten")
	})
	pickup.set_render_origin(render_origin)
	pickups_root.add_child(pickup)


func _build_chest_contents(chest_data: Dictionary) -> Array:
	var contents: Array = []
	var primary_reward: Dictionary = chest_data.get("reward", {}).duplicate(true)
	if not primary_reward.is_empty():
		contents.append(primary_reward)
	contents.append({"type": "heal", "amount": 2, "label": "Heiltrank"})
	for _index in range(3):
		contents.append({"type": "gold", "amount": 1, "label": "Muenze"})
	return contents


func _build_barrel_contents(loot_config: Dictionary) -> Array:
	var contents: Array = []
	var items_per_barrel: int = max(1, int(loot_config.get("items_per_barrel", 1)))
	var gold_ratio: float = clampf(float(loot_config.get("gold_ratio", 0.5)), 0.0, 1.0)
	for _index in range(items_per_barrel):
		if randf() <= gold_ratio:
			contents.append({"type": "gold", "amount": 1, "label": "Muenze"})
		else:
			contents.append({"type": "heal", "amount": 1, "label": "Heiltrank"})
	return contents


func _select_barrel_tiles(target_count: int) -> Array:
	var candidates: Array = []
	var reserved_tiles: Dictionary = {}
	var start_tile: Vector2i = level_data.get("start", Vector2i.ZERO)
	reserved_tiles[_tile_key(start_tile)] = true
	var exit_tile: Vector2i = level_data.get("exit", Vector2i(-1, -1))
	if exit_tile.x >= 0:
		reserved_tiles[_tile_key(exit_tile)] = true
	var chest_position: Vector2i = level_data.get("chest", {}).get("position", Vector2i(-1, -1))
	if chest_position.x >= 0:
		reserved_tiles[_tile_key(chest_position)] = true
	var amulet_position: Vector2i = level_data.get("amulet", {}).get("position", Vector2i(-1, -1))
	if amulet_position.x >= 0:
		reserved_tiles[_tile_key(amulet_position)] = true
	for enemy_data in level_data.get("enemies", []):
		reserved_tiles[_tile_key(enemy_data.get("position", Vector2i.ZERO))] = true

	var level_size: Vector2i = level_data.get("size", Vector2i.ZERO)
	for y in range(1, level_size.y - 1):
		for x in range(1, level_size.x - 1):
			var tile := Vector2i(x, y)
			if reserved_tiles.has(_tile_key(tile)):
				continue
			if not is_tile_walkable(tile):
				continue
			if tile.distance_to(start_tile) < 5:
				continue
			if _count_solid_neighbors(tile) == 0:
				continue
			candidates.append(tile)

	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%s:barrels" % [level_data.get("id", "level"), game.get_difficulty_id() if game != null and game.has_method("get_difficulty_id") else "normal"])
	for index in range(candidates.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var temp = candidates[index]
		candidates[index] = candidates[swap_index]
		candidates[swap_index] = temp

	var selected: Array = []
	for candidate in candidates:
		var too_close: bool = false
		for existing in selected:
			if (existing as Vector2i).distance_to(candidate) < 3:
				too_close = true
				break
		if too_close:
			continue
		selected.append(candidate)
		if selected.size() >= target_count:
			break
	return selected


func _count_solid_neighbors(tile: Vector2i) -> int:
	var count: int = 0
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if is_tile_hard_blocked(tile + offset):
			count += 1
	return count


func _spawn_enemies() -> void:
	remaining_enemies = 0
	engaged_enemy_count = 0
	for enemy_data in _get_scaled_enemies():
		var enemy: CharacterBody2D = EnemyScene.instantiate()
		enemy.position = tile_to_world(enemy_data.get("position", Vector2i.ZERO))
		enemy.setup(enemy_data.get("type", "zombie"), game, enemy_data)
		enemy.set_render_origin(render_origin)
		enemy.defeated.connect(_on_enemy_defeated)
		enemy.engagement_changed.connect(_on_enemy_engagement_changed)
		entity_layer.add_child(enemy)
		remaining_enemies += 1

	_update_exit_state()


func _get_scaled_enemies() -> Array:
	var base_enemies: Array = level_data.get("enemies", [])
	var base_count: int = base_enemies.size()
	if base_count == 0:
		return []

	var multiplier: float = 1.0
	if game != null and game.has_method("get_difficulty_multiplier"):
		multiplier = float(game.get_difficulty_multiplier())
	var target_count: int = maxi(1, int(round(float(base_count) * multiplier)))
	if target_count == base_count:
		var same_count: Array = []
		for enemy_data in base_enemies:
			same_count.append(enemy_data.duplicate(true))
		return same_count
	if target_count < base_count:
		return _sample_enemies_evenly(base_enemies, target_count)
	return _extend_enemy_list(base_enemies, target_count)


func _sample_enemies_evenly(base_enemies: Array, target_count: int) -> Array:
	var sampled: Array = []
	var last_index: int = -1
	for i in range(target_count):
		var ratio: float = (float(i) + 0.5) / float(target_count)
		var index: int = clampi(int(round(ratio * float(base_enemies.size()) - 0.5)), 0, base_enemies.size() - 1)
		if index <= last_index:
			index = mini(last_index + 1, base_enemies.size() - 1)
		last_index = index
		sampled.append(base_enemies[index].duplicate(true))
	return sampled


func _extend_enemy_list(base_enemies: Array, target_count: int) -> Array:
	var extended: Array = []
	var occupied: Dictionary = {}
	for enemy_data in base_enemies:
		var duplicated: Dictionary = enemy_data.duplicate(true)
		extended.append(duplicated)
		occupied[_tile_key(duplicated.get("position", Vector2i.ZERO))] = true

	var extra_index: int = 0
	while extended.size() < target_count:
		var source_data: Dictionary = base_enemies[extra_index % base_enemies.size()]
		var source_position: Vector2i = source_data.get("position", Vector2i.ZERO)
		var spawn_position: Vector2i = _find_extra_enemy_position(source_position, occupied)
		if spawn_position == source_position and occupied.has(_tile_key(spawn_position)):
			extra_index += 1
			if extra_index > base_enemies.size() * 16:
				break
			continue
		var duplicated_extra: Dictionary = source_data.duplicate(true)
		duplicated_extra["position"] = spawn_position
		extended.append(duplicated_extra)
		occupied[_tile_key(spawn_position)] = true
		extra_index += 1
	return extended


func _find_extra_enemy_position(source_position: Vector2i, occupied: Dictionary) -> Vector2i:
	var offsets := [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1),
		Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2),
		Vector2i(2, 1), Vector2i(-2, 1), Vector2i(2, -1), Vector2i(-2, -1)
	]
	for offset in offsets:
		var candidate: Vector2i = source_position + offset
		if not _is_enemy_spawn_tile_available(candidate, occupied):
			continue
		return candidate
	return source_position


func _is_enemy_spawn_tile_available(tile: Vector2i, occupied: Dictionary) -> bool:
	var level_size: Vector2i = level_data.get("size", Vector2i.ZERO)
	if tile.x < 0 or tile.y < 0 or tile.x >= level_size.x or tile.y >= level_size.y:
		return false
	if occupied.has(_tile_key(tile)):
		return false
	if _is_in_rects(tile, blocked_rects):
		return false
	if tile == level_data.get("start", Vector2i(-1, -1)):
		return false
	if tile == level_data.get("exit", Vector2i(-1, -1)):
		return false
	var chest_data: Dictionary = level_data.get("chest", {})
	if tile == chest_data.get("position", Vector2i(-1, -1)):
		return false
	return true


func _tile_key(tile: Vector2i) -> String:
	return "%d:%d" % [tile.x, tile.y]


func _get_line_tiles(from_tile: Vector2i, to_tile: Vector2i) -> Array:
	var tiles: Array = []
	var x0: int = from_tile.x
	var y0: int = from_tile.y
	var x1: int = to_tile.x
	var y1: int = to_tile.y
	var dx: int = absi(x1 - x0)
	var dy: int = absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx - dy

	while true:
		tiles.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2: int = err * 2
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy
	return tiles




func _on_enemy_engagement_changed(_enemy: Node, engaged: bool) -> void:
	if engaged:
		engaged_enemy_count += 1
	else:
		engaged_enemy_count = max(engaged_enemy_count - 1, 0)

	if game != null and game.has_method("set_combat_music_active"):
		game.set_combat_music_active(engaged_enemy_count > 0)


func _update_exit_state() -> void:
	if exit_portal == null:
		return

	var unlocked: bool = game != null and game.has_method("has_current_level_amulet") and game.has_current_level_amulet()
	exit_portal.set_locked(not unlocked)


func _on_enemy_defeated(enemy_node: Node, reward: Dictionary) -> void:
	var tile: Vector2i = world_to_tile(enemy_node.global_position)
	if not reward.is_empty():
		spawn_pickup(tile, reward)
	elif randf() < 0.22:
		spawn_pickup(tile, {"type": "heal", "amount": 1, "label": "Ration"})

	remaining_enemies = max(remaining_enemies - 1, 0)
	_update_exit_state()


func _validate_required_paths() -> void:
	var start_world: Vector2 = get_start_world_position()
	var chest_data: Dictionary = level_data.get("chest", {})
	var amulet_data: Dictionary = level_data.get("amulet", {})
	var exit_tile: Vector2i = level_data.get("exit", Vector2i(-1, -1))

	if not chest_data.is_empty():
		_validate_path_target("chest", start_world, tile_to_world(chest_data.get("position", Vector2i.ZERO)))
	if not amulet_data.is_empty():
		_validate_path_target("amulet", start_world, tile_to_world(amulet_data.get("position", Vector2i.ZERO)))
	if exit_tile.x >= 0:
		_validate_path_target("exit", start_world, tile_to_world(exit_tile))


func _validate_path_target(label: String, from_world: Vector2, to_world: Vector2) -> void:
	var path: Array = get_navigation_path_tiles(from_world, to_world, 0.0)
	if path.is_empty():
		push_error("Level '%s' has no valid path from start to %s." % [level_data.get("id", "unknown"), label])


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
