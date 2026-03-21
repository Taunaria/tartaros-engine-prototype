extends Area2D

const IsoMapper := preload("res://scripts/core/iso.gd")

var game: Node = null
var level_name: String = ""
var next_level_index: int = -1
var locked: bool = true
var render_origin: Vector2 = Vector2.ZERO


func setup(game_ref: Node, target_level_index: int, label: String) -> void:
	game = game_ref
	next_level_index = target_level_index
	level_name = label
	queue_redraw()


func set_locked(value: bool) -> void:
	locked = value
	queue_redraw()


func set_active(_active: bool) -> void:
	pass


func set_render_origin(new_render_origin: Vector2) -> void:
	render_origin = new_render_origin
	z_index = 1000 + IsoMapper.entity_sort_z_for_foot(global_position) + 1
	queue_redraw()


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _draw() -> void:
	var base: Vector2 = IsoMapper.render_offset(position, render_origin)
	var frame_color: Color = Color8(74, 55, 34)
	var portal_color: Color = Color8(93, 188, 217) if not locked else Color8(88, 88, 88)
	draw_rect(Rect2(base + Vector2(-14, -16), Vector2(28, 32)), frame_color)
	draw_rect(Rect2(base + Vector2(-10, -12), Vector2(20, 24)), portal_color)


func _on_body_entered(body: Node) -> void:
	if locked or not body.is_in_group("player") or game == null:
		return

	game.advance_to_level(next_level_index)
