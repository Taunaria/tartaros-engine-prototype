extends "res://scripts/props/container.gd"

const BarrelClosedPath := "res://output/imagegen/props/barrel_closed.png"
const BarrelBrokenPath := "res://output/imagegen/props/barrel_broken.png"
const BackgroundStepThresholdSq := 324.0
const CropPadding := 2

static var _texture_cache: Dictionary = {}


func _get_open_xp_reward() -> int:
	return 10


func _draw() -> void:
	var base: Vector2 = IsoMapper.render_offset(position, render_origin)
	var texture: Texture2D = _load_runtime_texture(BarrelBrokenPath) if opened else _load_runtime_texture(BarrelClosedPath)
	if texture == null:
		_draw_fallback_barrel(base)
		return

	var texture_size: Vector2 = texture.get_size()
	var target_height: float = 62.0
	var scale: float = target_height / maxf(texture_size.y, 1.0)
	var draw_size: Vector2 = texture_size * scale
	var barrel_rect := Rect2(base + Vector2(-draw_size.x * 0.5, -draw_size.y + 16.0), draw_size)
	draw_rect(Rect2(barrel_rect.position + Vector2(6, 10), Vector2(maxf(barrel_rect.size.x - 12.0, 8.0), 8.0)), Color(0, 0, 0, 0.16))
	draw_texture_rect(texture, barrel_rect, false)


func _draw_fallback_barrel(base: Vector2) -> void:
	var body_color: Color = Color8(153, 91, 37) if not opened else Color8(112, 74, 44)
	var band_color: Color = Color8(58, 62, 72)
	draw_rect(Rect2(base + Vector2(-12, 8), Vector2(24, 7)), Color(0, 0, 0, 0.16))
	draw_rect(Rect2(base + Vector2(-12, -18), Vector2(24, 30)), body_color)
	draw_rect(Rect2(base + Vector2(-12, -16), Vector2(24, 4)), band_color)
	draw_rect(Rect2(base + Vector2(-12, -2), Vector2(24, 4)), band_color)
	if opened:
		draw_line(base + Vector2(-10, -18), base + Vector2(6, -4), Color8(88, 56, 31), 3.0)
		draw_line(base + Vector2(2, -17), base + Vector2(12, -7), Color8(88, 56, 31), 3.0)


static func _load_runtime_texture(path: String) -> Texture2D:
	var absolute_path: String = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute_path):
		_texture_cache[path] = {
			"mtime": -1,
			"texture": null
		}
		return null
	var modified_time: int = FileAccess.get_modified_time(absolute_path)
	var cached_entry: Variant = _texture_cache.get(path)
	if cached_entry is Dictionary and cached_entry.get("mtime", -1) == modified_time:
		return cached_entry.get("texture", null)
	var image := Image.new()
	var error: Error = image.load(absolute_path)
	if error != OK or image.is_empty():
		push_warning("Barrel: failed to load texture %s" % path)
		return null
	image = _prepare_barrel_image(image)
	var texture := ImageTexture.create_from_image(image)
	_texture_cache[path] = {
		"mtime": modified_time,
		"texture": texture
	}
	return texture


static func _prepare_barrel_image(source_image: Image) -> Image:
	var image: Image = source_image.duplicate()
	image.convert(Image.FORMAT_RGBA8)
	var width: int = image.get_width()
	var height: int = image.get_height()
	if width <= 0 or height <= 0:
		return image

	var background_mask := PackedByteArray()
	background_mask.resize(width * height)
	var queue: Array[Vector2i] = []
	for x in range(width):
		queue.append(Vector2i(x, 0))
		queue.append(Vector2i(x, height - 1))
	for y in range(height):
		queue.append(Vector2i(0, y))
		queue.append(Vector2i(width - 1, y))

	var read_index: int = 0
	while read_index < queue.size():
		var point: Vector2i = queue[read_index]
		read_index += 1
		var point_index: int = point.y * width + point.x
		if background_mask[point_index] == 1:
			continue
		background_mask[point_index] = 1
		var base: Color = image.get_pixelv(point)
		for neighbor in [
			Vector2i(point.x - 1, point.y),
			Vector2i(point.x + 1, point.y),
			Vector2i(point.x, point.y - 1),
			Vector2i(point.x, point.y + 1)
		]:
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= width or neighbor.y >= height:
				continue
			var neighbor_index: int = neighbor.y * width + neighbor.x
			if background_mask[neighbor_index] == 1:
				continue
			var sample: Color = image.get_pixelv(neighbor)
			if _color_distance_sq(base, sample) <= BackgroundStepThresholdSq:
				queue.append(neighbor)

	for y in range(height):
		for x in range(width):
			if background_mask[y * width + x] != 1:
				continue
			var color: Color = image.get_pixel(x, y)
			image.set_pixel(x, y, Color(color.r, color.g, color.b, 0.0))

	var used_rect: Rect2i = image.get_used_rect()
	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		return image

	var crop_position := Vector2i(max(used_rect.position.x - CropPadding, 0), max(used_rect.position.y - CropPadding, 0))
	var crop_end := Vector2i(min(used_rect.end.x + CropPadding, width), min(used_rect.end.y + CropPadding, height))
	return image.get_region(Rect2i(crop_position, crop_end - crop_position))


static func _color_distance_sq(a: Color, b: Color) -> float:
	var dr: float = (a.r - b.r) * 255.0
	var dg: float = (a.g - b.g) * 255.0
	var db: float = (a.b - b.b) * 255.0
	return dr * dr + dg * dg + db * db
