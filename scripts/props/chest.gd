extends "res://scripts/props/container.gd"

const ChestClosedTexture := preload("res://output/imagegen/props/chest_closed.png")
const ChestOpenTexture := preload("res://output/imagegen/props/chest_open.png")


func _draw() -> void:
	var base: Vector2 = IsoMapper.render_offset(position, render_origin)
	var texture: Texture2D = ChestOpenTexture if opened else ChestClosedTexture
	if texture == null:
		return

	var texture_size: Vector2 = texture.get_size()
	var target_height: float = 72.0
	var scale: float = target_height / maxf(texture_size.y, 1.0)
	var draw_size: Vector2 = texture_size * scale
	var chest_rect := Rect2(base + Vector2(-draw_size.x * 0.5, -draw_size.y + 18.0), draw_size)
	draw_rect(Rect2(chest_rect.position + Vector2(6, 10), Vector2(chest_rect.size.x - 12.0, 10.0)), Color(0, 0, 0, 0.18))
	draw_texture_rect(texture, chest_rect, false)
