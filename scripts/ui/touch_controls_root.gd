extends Control
class_name TouchControlsRoot

@export var joystick_deadzone := 0.18
@export var joystick_max_radius := 92.0

var game: Node = null
var mobile_enabled: bool = false
var gameplay_active: bool = false
var move_touch_index: int = -1
var aim_touch_index: int = -1
var move_vector: Vector2 = Vector2.ZERO
var aim_screen_position: Vector2 = Vector2.ZERO
var attack_held: bool = false

@onready var virtual_joystick: Control = $VirtualJoystick
@onready var right_touch_handler: Control = $RightTouchHandler


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	virtual_joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_touch_handler.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_unhandled_input(true)
	_reset_local_state()
	_sync_game_state()
	_update_visibility()


func set_game_ref(game_ref: Node) -> void:
	game = game_ref
	_sync_game_state()


func set_mobile_enabled(enabled: bool) -> void:
	mobile_enabled = enabled
	if not mobile_enabled:
		gameplay_active = false
	_reset_local_state()
	_update_visibility()


func set_gameplay_active(active: bool) -> void:
	gameplay_active = active and mobile_enabled
	_reset_local_state()
	_update_visibility()


func _unhandled_input(event: InputEvent) -> void:
	if not gameplay_active:
		return

	if event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if move_touch_index == -1 and _is_in_joystick_zone(event.position):
			move_touch_index = event.index
			move_vector = _calculate_move_vector(event.position)
			_sync_move_vector()
			queue_redraw()
			return

		if aim_touch_index == -1 and _is_in_aim_zone(event.position):
			aim_touch_index = event.index
			aim_screen_position = event.position
			attack_held = true
			_sync_aim_state(true, true)
			queue_redraw()
			return
		return

	if event.index == move_touch_index:
		move_touch_index = -1
		move_vector = Vector2.ZERO
		_sync_move_vector()
		queue_redraw()
		return

	if event.index == aim_touch_index:
		aim_touch_index = -1
		attack_held = false
		_sync_aim_state(false)
		queue_redraw()


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index == move_touch_index:
		move_vector = _calculate_move_vector(event.position)
		_sync_move_vector()
		queue_redraw()
		return

	if event.index == aim_touch_index:
		aim_screen_position = event.position
		attack_held = true
		_sync_aim_state(true)
		queue_redraw()


func _is_in_joystick_zone(screen_position: Vector2) -> bool:
	return virtual_joystick.get_global_rect().grow(28.0).has_point(screen_position)


func _is_in_aim_zone(screen_position: Vector2) -> bool:
	return right_touch_handler.get_global_rect().has_point(screen_position)


func _calculate_move_vector(screen_position: Vector2) -> Vector2:
	var joystick_rect: Rect2 = virtual_joystick.get_global_rect()
	var center: Vector2 = joystick_rect.get_center()
	var raw_vector: Vector2 = screen_position - center
	var max_radius: float = maxf(joystick_max_radius, minf(joystick_rect.size.x, joystick_rect.size.y) * 0.5)
	if raw_vector.length_squared() <= 0.001:
		return Vector2.ZERO

	var clamped_vector: Vector2 = raw_vector.limit_length(max_radius)
	var normalized_strength: float = clampf(clamped_vector.length() / max_radius, 0.0, 1.0)
	if normalized_strength <= joystick_deadzone:
		return Vector2.ZERO

	var remapped_strength: float = (normalized_strength - joystick_deadzone) / maxf(0.001, 1.0 - joystick_deadzone)
	return clamped_vector.normalized() * clampf(remapped_strength, 0.0, 1.0)


func _sync_move_vector() -> void:
	if game != null and game.has_method("set_touch_move_vector"):
		game.set_touch_move_vector(move_vector)


func _sync_aim_state(held: bool, pulse_attack: bool = false) -> void:
	if game == null:
		return
	if game.has_method("set_touch_aim_screen_position"):
		game.set_touch_aim_screen_position(aim_screen_position)
	if game.has_method("set_touch_attack_held"):
		game.set_touch_attack_held(held)
	if pulse_attack and game.has_method("set_touch_attack_pressed"):
		game.set_touch_attack_pressed()


func _sync_game_state() -> void:
	_sync_move_vector()
	if game != null and game.has_method("set_touch_aim_screen_position"):
		game.set_touch_aim_screen_position(aim_screen_position if gameplay_active else _get_default_aim_screen_position())
	if game != null and game.has_method("set_touch_attack_held"):
		game.set_touch_attack_held(attack_held and gameplay_active)
	if not gameplay_active and game != null and game.has_method("set_touch_move_vector"):
		game.set_touch_move_vector(Vector2.ZERO)


func _reset_local_state() -> void:
	move_touch_index = -1
	aim_touch_index = -1
	move_vector = Vector2.ZERO
	aim_screen_position = _get_default_aim_screen_position()
	attack_held = false
	if game != null and game.has_method("reset_touch_input_state"):
		game.reset_touch_input_state()
	else:
		_sync_game_state()
	queue_redraw()


func _get_default_aim_screen_position() -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.length_squared() <= 0.001:
		return Vector2.ZERO
	return viewport_size * 0.5


func _update_visibility() -> void:
	visible = mobile_enabled and gameplay_active
	queue_redraw()


func _draw() -> void:
	if not visible:
		return

	var joystick_rect: Rect2 = virtual_joystick.get_global_rect()
	var base_center: Vector2 = joystick_rect.get_center()
	var base_radius: float = minf(joystick_rect.size.x, joystick_rect.size.y) * 0.36
	var knob_radius: float = base_radius * 0.48
	var base_alpha: float = 0.22 if move_touch_index == -1 else 0.36
	var knob_alpha: float = 0.54 if move_touch_index == -1 else 0.85
	var knob_offset: Vector2 = move_vector * base_radius * 0.85
	draw_circle(base_center, base_radius, Color(0.08, 0.10, 0.14, base_alpha))
	draw_arc(base_center, base_radius, 0.0, TAU, 48, Color(0.92, 0.95, 1.0, 0.36), 3.0)
	draw_circle(base_center + knob_offset, knob_radius, Color(0.95, 0.98, 1.0, knob_alpha))
	draw_arc(base_center + knob_offset, knob_radius, 0.0, TAU, 32, Color(0.18, 0.24, 0.32, 0.5), 2.0)
