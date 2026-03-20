extends Node2D
class_name BlockTile

const IsoMapper := preload("res://scripts/core/iso.gd")
const TILE_WIDTH := IsoMapper.RENDER_TILE_WIDTH
const TILE_HEIGHT := IsoMapper.RENDER_TILE_HEIGHT
const HALF_TILE_WIDTH := TILE_WIDTH * 0.5
const HALF_TILE_HEIGHT := TILE_HEIGHT * 0.5
const DEFAULT_HEIGHT_STEP := HALF_TILE_HEIGHT
const MATERIALS := {
	"grass": {
		"top": Color8(125, 198, 67),
		"top_light": Color8(155, 224, 83),
		"left": Color8(159, 100, 56),
		"right": Color8(127, 76, 43),
		"outline": Color8(81, 58, 31)
	},
	"stone": {
		"top": Color8(181, 189, 199),
		"top_light": Color8(214, 221, 227),
		"left": Color8(126, 136, 147),
		"right": Color8(101, 109, 119),
		"outline": Color8(75, 81, 88)
	},
	"wood": {
		"top": Color8(167, 106, 56),
		"top_light": Color8(192, 130, 72),
		"left": Color8(144, 85, 44),
		"right": Color8(122, 72, 38),
		"outline": Color8(84, 45, 19)
	}
}

var grid_position: Vector2i = Vector2i.ZERO
var tile_type: String = "grass"
var render_origin: Vector2 = Vector2.ZERO
var visual_height: int = 0
var height_step: float = DEFAULT_HEIGHT_STEP


func _ready() -> void:
	queue_redraw()


func setup(
		new_tile_type: String,
		new_grid_position: Vector2i,
		new_render_origin: Vector2 = Vector2.ZERO,
		new_visual_height: int = 0
) -> void:
	tile_type = new_tile_type
	grid_position = new_grid_position
	render_origin = new_render_origin
	visual_height = maxi(new_visual_height, 0)
	position = render_origin + grid_to_screen(grid_position)
	z_index = _get_base_z_index()
	height_step = DEFAULT_HEIGHT_STEP
	queue_redraw()


static func grid_to_screen(cell: Vector2i) -> Vector2:
	return IsoMapper.grid_to_screen(cell)


static func get_default_height_step() -> float:
	return DEFAULT_HEIGHT_STEP


func _get_base_z_index() -> int:
	return (grid_position.x + grid_position.y) * 10


func _draw() -> void:
	var material: Dictionary = MATERIALS.get(tile_type, MATERIALS["grass"])
	if visual_height > 0:
		for layer in range(visual_height):
			var top_y: float = -height_step * float(layer + 1)
			var bottom_y: float = top_y + height_step
			_draw_face(_get_left_face_points(top_y, bottom_y), material["left"], material["outline"])
			_draw_face(_get_right_face_points(top_y, bottom_y), material["right"], material["outline"])
			_draw_side_detail(top_y, bottom_y, material["outline"].lightened(0.12))

	var surface_y: float = -height_step * float(visual_height)
	_draw_face(_get_top_face_points(surface_y), material["top"], material["outline"])
	_draw_top_detail(surface_y, material["top_light"], material["outline"].lightened(0.2))


func _draw_face(points: PackedVector2Array, fill_color: Color, outline_color: Color) -> void:
	draw_colored_polygon(points, fill_color)
	draw_polyline(_close_polygon(points), outline_color, 1.0)


func _draw_top_detail(surface_y: float, highlight_color: Color, line_color: Color) -> void:
	var inset := PackedVector2Array([
		Vector2(0.0, surface_y - HALF_TILE_HEIGHT * 0.52),
		Vector2(HALF_TILE_WIDTH * 0.56, surface_y),
		Vector2(0.0, surface_y + HALF_TILE_HEIGHT * 0.52),
		Vector2(-HALF_TILE_WIDTH * 0.56, surface_y)
	])
	var inset_color := highlight_color
	inset_color.a = 0.45
	draw_colored_polygon(inset, inset_color)
	draw_line(
		Vector2(-HALF_TILE_WIDTH * 0.38, surface_y - HALF_TILE_HEIGHT * 0.19),
		Vector2(HALF_TILE_WIDTH * 0.38, surface_y + HALF_TILE_HEIGHT * 0.19),
		line_color,
		1.0
	)
	draw_line(
		Vector2(-HALF_TILE_WIDTH * 0.38, surface_y + HALF_TILE_HEIGHT * 0.19),
		Vector2(HALF_TILE_WIDTH * 0.38, surface_y - HALF_TILE_HEIGHT * 0.19),
		line_color,
		1.0
	)


func _draw_side_detail(top_y: float, bottom_y: float, line_color: Color) -> void:
	var mid_y: float = lerpf(top_y, bottom_y, 0.5)
	draw_line(
		Vector2(-HALF_TILE_WIDTH, mid_y),
		Vector2(0.0, mid_y + HALF_TILE_HEIGHT),
		line_color,
		1.0
	)
	draw_line(
		Vector2(0.0, mid_y + HALF_TILE_HEIGHT),
		Vector2(HALF_TILE_WIDTH, mid_y),
		line_color,
		1.0
	)


func _get_top_face_points(surface_y: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, surface_y - HALF_TILE_HEIGHT),
		Vector2(HALF_TILE_WIDTH, surface_y),
		Vector2(0.0, surface_y + HALF_TILE_HEIGHT),
		Vector2(-HALF_TILE_WIDTH, surface_y)
	])


func _get_left_face_points(top_y: float, bottom_y: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-HALF_TILE_WIDTH, top_y),
		Vector2(0.0, top_y + HALF_TILE_HEIGHT),
		Vector2(0.0, bottom_y + HALF_TILE_HEIGHT),
		Vector2(-HALF_TILE_WIDTH, bottom_y)
	])


func _get_right_face_points(top_y: float, bottom_y: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, top_y + HALF_TILE_HEIGHT),
		Vector2(HALF_TILE_WIDTH, top_y),
		Vector2(HALF_TILE_WIDTH, bottom_y),
		Vector2(0.0, bottom_y + HALF_TILE_HEIGHT)
	])


func _close_polygon(points: PackedVector2Array) -> PackedVector2Array:
	var closed := PackedVector2Array(points)
	if not closed.is_empty():
		closed.append(closed[0])
	return closed
