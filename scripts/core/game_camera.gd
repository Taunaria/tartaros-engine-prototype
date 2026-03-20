extends Camera2D
class_name GameCamera

@export var default_zoom: Vector2 = Vector2(0.33, 0.33)
@export var default_position_smoothing_enabled: bool = true
@export var default_position_smoothing_speed: float = 9.0


func apply_defaults() -> void:
	zoom = default_zoom
	position_smoothing_enabled = default_position_smoothing_enabled
	position_smoothing_speed = default_position_smoothing_speed
