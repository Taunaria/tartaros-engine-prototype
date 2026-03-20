extends Node2D

var grid_position: Vector2i = Vector2i.ZERO
var label_text: String = "Entity"
var marker_color: Color = Color8(201, 72, 72)


func setup(new_grid_position: Vector2i, new_label_text: String, new_color: Color) -> void:
	grid_position = new_grid_position
	label_text = new_label_text
	marker_color = new_color
	position = Vector2(
		(grid_position.x - grid_position.y) * BlockTile.TILE_WIDTH * 0.5,
		(grid_position.x + grid_position.y) * BlockTile.TILE_HEIGHT * 0.5
	)
	z_index = grid_position.x + grid_position.y + 1000
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2(-10, 14), Vector2(20, 8)), Color(0, 0, 0, 0.18))
	draw_rect(Rect2(Vector2(-8, -22), Vector2(16, 24)), marker_color)
	draw_rect(Rect2(Vector2(-6, -34), Vector2(12, 12)), marker_color.lightened(0.2))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-18, -42),
		label_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		44,
		12,
		Color8(40, 40, 40)
	)
