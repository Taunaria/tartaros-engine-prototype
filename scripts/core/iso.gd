extends RefCounted
class_name IsoMapper

const LOGIC_TILE_SIZE := 32.0
const RENDER_TILE_WIDTH := 64.0
const RENDER_TILE_HEIGHT := 32.0
const HALF_RENDER_TILE_WIDTH := RENDER_TILE_WIDTH * 0.5
const HALF_RENDER_TILE_HEIGHT := RENDER_TILE_HEIGHT * 0.5
const SORT_LAYER_STEP := 40
const ENTITY_SORT_OFFSET := 20


static func tile_to_logic_center(tile: Vector2i) -> Vector2:
	return Vector2(
		tile.x * LOGIC_TILE_SIZE + LOGIC_TILE_SIZE * 0.5,
		tile.y * LOGIC_TILE_SIZE + LOGIC_TILE_SIZE * 0.5
	)


static func grid_to_screen(tile: Vector2i) -> Vector2:
	return Vector2(
		(tile.x - tile.y) * HALF_RENDER_TILE_WIDTH,
		(tile.x + tile.y) * HALF_RENDER_TILE_HEIGHT
	)


static func logic_to_screen(logic_position: Vector2, render_origin: Vector2) -> Vector2:
	return Vector2(
		logic_position.x - logic_position.y,
		(logic_position.x + logic_position.y) * 0.5 - HALF_RENDER_TILE_HEIGHT
	) + render_origin


static func render_offset(logic_position: Vector2, render_origin: Vector2) -> Vector2:
	return logic_to_screen(logic_position, render_origin) - logic_position


static func sort_key_for_logic(logic_position: Vector2) -> int:
	return floori(logic_position.x / LOGIC_TILE_SIZE) + floori(logic_position.y / LOGIC_TILE_SIZE)


static func tile_sort_base(tile: Vector2i) -> int:
	return (tile.x + tile.y) * SORT_LAYER_STEP


static func entity_sort_z_for_foot(logic_position: Vector2) -> int:
	var depth_units: float = ((logic_position.x + logic_position.y) / LOGIC_TILE_SIZE) - 1.0
	return floori(depth_units * SORT_LAYER_STEP) + ENTITY_SORT_OFFSET


static func level_render_origin(level_size: Vector2i) -> Vector2:
	return Vector2(level_size.y * HALF_RENDER_TILE_WIDTH + 160.0, 120.0)
