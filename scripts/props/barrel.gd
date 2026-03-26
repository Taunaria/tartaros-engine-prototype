extends "res://scripts/props/container.gd"

const BarrelClosedPath := "res://output/imagegen/props/barrel_closed.png"
const BarrelBrokenPath := "res://output/imagegen/props/barrel_broken.png"

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
	var texture := ImageTexture.create_from_image(image)
	_texture_cache[path] = {
		"mtime": modified_time,
		"texture": texture
	}
	return texture
