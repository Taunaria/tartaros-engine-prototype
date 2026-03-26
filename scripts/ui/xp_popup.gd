extends Node2D
class_name XpPopup

@export var rise_speed: float = 36.0
@export var lifetime: float = 1.0
@export var pop_duration: float = 0.12
@export var pop_scale_bonus: float = 0.12

var _time: float = 0.0

@onready var label: Label = $Label


func setup(amount: int, world_position: Vector2) -> void:
	setup_text("+%d XP" % amount, world_position, Color(1.0, 1.0, 0.72, 1.0))


func setup_text(text: String, world_position: Vector2, color: Color = Color(1.0, 1.0, 0.72, 1.0)) -> void:
	position = world_position
	label.text = text
	_time = 0.0
	scale = Vector2.ONE
	modulate = color
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	position.y -= rise_speed * delta
	var pop_ratio: float = 1.0 - clampf(_time / pop_duration, 0.0, 1.0)
	scale = Vector2.ONE * (1.0 + pop_ratio * pop_scale_bonus)
	modulate.a = clampf(1.0 - _time / lifetime, 0.0, 1.0)
	if _time >= lifetime:
		queue_free()
