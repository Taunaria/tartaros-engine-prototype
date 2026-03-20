extends Camera2D
class_name GameCamera

const DEFAULT_ZOOM := Vector2(0.33, 0.33)
const DEFAULT_POSITION_SMOOTHING_ENABLED := true
const DEFAULT_POSITION_SMOOTHING_SPEED := 9.0


func apply_defaults() -> void:
	zoom = DEFAULT_ZOOM
	position_smoothing_enabled = DEFAULT_POSITION_SMOOTHING_ENABLED
	position_smoothing_speed = DEFAULT_POSITION_SMOOTHING_SPEED
