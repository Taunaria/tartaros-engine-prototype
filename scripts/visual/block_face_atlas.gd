extends RefCounted
class_name BlockFaceAtlas

const ATLAS_SIZE := Vector2i(128, 96)
const FACE_REGIONS := {
	"grass": {
		"top_texture_region": Rect2(0, 0, 64, 32),
		"left_texture_region": Rect2(64, 0, 32, 32),
		"right_texture_region": Rect2(96, 0, 32, 32)
	},
	"stone": {
		"top_texture_region": Rect2(0, 32, 64, 32),
		"left_texture_region": Rect2(64, 32, 32, 32),
		"right_texture_region": Rect2(96, 32, 32, 32)
	},
	"wood": {
		"top_texture_region": Rect2(0, 64, 64, 32),
		"left_texture_region": Rect2(64, 64, 32, 32),
		"right_texture_region": Rect2(96, 64, 32, 32)
	}
}

static var _texture: Texture2D = null


static func get_regions() -> Dictionary:
	return FACE_REGIONS


static func get_texture() -> Texture2D:
	if _texture != null:
		return _texture

	var image := Image.create(ATLAS_SIZE.x, ATLAS_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	_draw_material_row(
		image,
		0,
		Color8(125, 198, 67),
		Color8(155, 224, 83),
		Color8(158, 100, 56),
		Color8(127, 77, 43),
		"grass"
	)
	_draw_material_row(
		image,
		32,
		Color8(181, 189, 199),
		Color8(214, 221, 227),
		Color8(126, 136, 147),
		Color8(101, 109, 119),
		"stone"
	)
	_draw_material_row(
		image,
		64,
		Color8(167, 106, 56),
		Color8(192, 130, 72),
		Color8(144, 85, 44),
		Color8(120, 71, 37),
		"wood"
	)

	_texture = ImageTexture.create_from_image(image)
	return _texture


static func _draw_material_row(
	image: Image,
	row_y: int,
	top_base: Color,
	top_highlight: Color,
	left_base: Color,
	right_base: Color,
	pattern: String
) -> void:
	var top_points := PackedVector2Array([
		Vector2(32, 1),
		Vector2(63, 16),
		Vector2(32, 31),
		Vector2(1, 16)
	])
	var left_points := PackedVector2Array([
		Vector2(16, 0),
		Vector2(31, 8),
		Vector2(31, 31),
		Vector2(0, 24),
		Vector2(0, 8)
	])
	var right_points := PackedVector2Array([
		Vector2(1, 8),
		Vector2(16, 0),
		Vector2(31, 8),
		Vector2(31, 24),
		Vector2(0, 31)
	])

	_fill_polygon(image, Vector2i(0, row_y), top_points, top_base, pattern, 1)
	_fill_polygon(image, Vector2i(64, row_y), left_points, left_base, pattern, 2)
	_fill_polygon(image, Vector2i(96, row_y), right_points, right_base, pattern, 3)
	_fill_polygon(
		image,
		Vector2i(0, row_y),
		PackedVector2Array([Vector2(32, 5), Vector2(57, 17), Vector2(32, 28), Vector2(8, 17)]),
		top_highlight,
		"highlight",
		4
	)
	_stroke_polygon(image, Vector2i(0, row_y), top_points, top_base.darkened(0.35))
	_stroke_polygon(image, Vector2i(64, row_y), left_points, left_base.darkened(0.3))
	_stroke_polygon(image, Vector2i(96, row_y), right_points, right_base.darkened(0.3))


static func _fill_polygon(
	image: Image,
	origin: Vector2i,
	points: PackedVector2Array,
	base_color: Color,
	pattern: String,
	seed_value: int
) -> void:
	var bounds := _get_bounds(points)
	for y in range(bounds.position.y, bounds.end.y + 1):
		for x in range(bounds.position.x, bounds.end.x + 1):
			var point := Vector2(x + 0.5, y + 0.5)
			if not Geometry2D.is_point_in_polygon(point, points):
				continue

			var atlas_x := origin.x + x
			var atlas_y := origin.y + y
			var color := _shade_pixel(base_color, x, y, pattern, seed_value)
			image.set_pixel(atlas_x, atlas_y, color)


static func _stroke_polygon(image: Image, origin: Vector2i, points: PackedVector2Array, color: Color) -> void:
	for index in range(points.size()):
		var start := points[index]
		var finish := points[(index + 1) % points.size()]
		_draw_line(
			image,
			Vector2i(roundi(start.x), roundi(start.y)) + origin,
			Vector2i(roundi(finish.x), roundi(finish.y)) + origin,
			color
		)


static func _draw_line(image: Image, start: Vector2i, finish: Vector2i, color: Color) -> void:
	var x0 := start.x
	var y0 := start.y
	var x1 := finish.x
	var y1 := finish.y
	var dx := absi(x1 - x0)
	var sx := 1 if x0 < x1 else -1
	var dy := -absi(y1 - y0)
	var sy := 1 if y0 < y1 else -1
	var error := dx + dy

	while true:
		if x0 >= 0 and y0 >= 0 and x0 < ATLAS_SIZE.x and y0 < ATLAS_SIZE.y:
			image.set_pixel(x0, y0, color)
		if x0 == x1 and y0 == y1:
			break
		var error_twice := error * 2
		if error_twice >= dy:
			error += dy
			x0 += sx
		if error_twice <= dx:
			error += dx
			y0 += sy


static func _shade_pixel(base_color: Color, x: int, y: int, pattern: String, seed_value: int) -> Color:
	var shade := 0.0
	match pattern:
		"grass":
			shade = (float((x * 7 + y * 13 + seed_value * 3) % 9) / 8.0 - 0.5) * 0.18
			if (x + y + seed_value) % 11 < 3:
				shade += 0.08
		"stone":
			shade = (float((x * 5 + y * 9 + seed_value * 7) % 10) / 9.0 - 0.5) * 0.2
			if (x / 5 + y / 4 + seed_value) % 3 == 0:
				shade += 0.06
		"wood":
			shade = sin(float(x + seed_value) * 0.55) * 0.06
			if x % 6 == 0 or x % 6 == 1:
				shade -= 0.08
		"highlight":
			shade = (float((x * 3 + y * 5 + seed_value) % 6) / 5.0) * 0.07
		_:
			shade = 0.0

	if shade > 0.0:
		return base_color.lightened(shade)
	return base_color.darkened(-shade)


static func _get_bounds(points: PackedVector2Array) -> Rect2i:
	var min_x := int(points[0].x)
	var max_x := int(points[0].x)
	var min_y := int(points[0].y)
	var max_y := int(points[0].y)
	for point in points:
		min_x = mini(min_x, int(point.x))
		max_x = maxi(max_x, int(point.x))
		min_y = mini(min_y, int(point.y))
		max_y = maxi(max_y, int(point.y))
	return Rect2i(min_x, min_y, max_x - min_x, max_y - min_y)
