extends CharacterBody2D

signal hp_changed(current_hp: int, max_hp: int)
signal weapon_changed(weapon_data: Dictionary)
signal died

const WeaponDB := preload("res://data/weapons/weapon_db.gd")
const IsoMapper := preload("res://scripts/core/iso.gd")
const CombatDebug := preload("res://scripts/core/combat_debug.gd")

@export var move_speed := 140.0
@export var max_hp := 12
@export var attack_reach := 32.0
@export var attack_width := 24.0
@export var attack_active_duration := 0.24
@export var debug_attack := false

var hp := max_hp
var control_enabled := true
var weapon_inventory: Dictionary = {}
var current_weapon_id := WeaponDB.get_default_weapon_id()
var last_direction := Vector2.DOWN
var attack_timer := 0.0
var attack_active_timer := 0.0
var hit_timer := 0.0
var attack_flash_timer := 0.0
var render_origin: Vector2 = Vector2.ZERO
var hit_targets: Dictionary = {}

@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D


func _ready() -> void:
	reset_for_new_run()


func _physics_process(delta: float) -> void:
	_tick_timers(delta)

	if control_enabled:
		_handle_movement()
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	z_index = 1000 + IsoMapper.sort_key_for_logic(global_position)
	_update_attack_hitbox()
	_handle_attack_input()
	_update_attack_state()


func _draw() -> void:
	var base: Vector2 = _get_render_offset()
	var body_color: Color = Color8(188, 120, 72)
	var armor_color: Color = Color8(111, 138, 171)
	if hit_timer > 0.0:
		body_color = Color8(236, 117, 117)
		armor_color = Color8(255, 200, 200)

	draw_rect(Rect2(base + Vector2(-10, 8), Vector2(20, 8)), Color(0, 0, 0, 0.18))
	draw_rect(Rect2(base + Vector2(-10, -8), Vector2(20, 16)), body_color)
	draw_rect(Rect2(base + Vector2(-8, -16), Vector2(16, 10)), armor_color)
	draw_rect(Rect2(base + Vector2(-4, -20), Vector2(8, 4)), Color8(227, 214, 179))

	if attack_flash_timer > 0.0:
		var weapon: Dictionary = get_current_weapon()
		var tip_logic: Vector2 = position + last_direction * _get_attack_visual_length(weapon)
		var tip: Vector2 = IsoMapper.logic_to_screen(tip_logic, render_origin) - position
		draw_line(base, tip, weapon["color"], 4.0)

	if CombatDebug.enabled:
		_draw_debug_shapes()


func reset_for_new_run() -> void:
	hp = max_hp
	weapon_inventory.clear()
	unlock_weapon(WeaponDB.get_default_weapon_id(), true)
	equip_weapon(WeaponDB.get_default_weapon_id())
	attack_timer = 0.0
	attack_active_timer = 0.0
	hit_timer = 0.0
	attack_flash_timer = 0.0
	control_enabled = true
	last_direction = Vector2.DOWN
	hit_targets.clear()
	attack_area.monitoring = false
	emit_signal("hp_changed", hp, max_hp)
	queue_redraw()


func set_control_enabled(enabled: bool) -> void:
	control_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO


func set_render_origin(new_render_origin: Vector2) -> void:
	render_origin = new_render_origin
	z_index = 1000 + IsoMapper.sort_key_for_logic(global_position)
	queue_redraw()


func get_visual_position() -> Vector2:
	return IsoMapper.logic_to_screen(global_position, render_origin)


func unlock_weapon(weapon_id: String, silent: bool = false) -> bool:
	if weapon_inventory.has(weapon_id):
		return false

	weapon_inventory[weapon_id] = true
	if not silent:
		equip_weapon(weapon_id)
	return true


func equip_weapon(weapon_id: String) -> void:
	current_weapon_id = weapon_id
	emit_signal("weapon_changed", get_current_weapon())
	_update_attack_hitbox()
	queue_redraw()


func get_current_weapon() -> Dictionary:
	return WeaponDB.get_weapon(current_weapon_id)


func heal(amount: int) -> int:
	var previous: int = hp
	hp = clampi(hp + amount, 0, max_hp)
	emit_signal("hp_changed", hp, max_hp)
	return hp - previous


func take_damage(amount: int) -> void:
	if hit_timer > 0.0 or hp <= 0:
		return

	hp = max(hp - amount, 0)
	hit_timer = 0.45
	emit_signal("hp_changed", hp, max_hp)
	queue_redraw()
	if hp <= 0:
		control_enabled = false
		emit_signal("died")


func _handle_movement() -> void:
	var direction: Vector2 = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

	if direction.length_squared() > 0.0:
		last_direction = _to_cardinal_direction(direction)
	velocity = direction.normalized() * move_speed
	queue_redraw()


func _handle_attack_input() -> void:
	if not Input.is_action_just_pressed("attack"):
		return

	if attack_timer > 0.0 or attack_active_timer > 0.0:
		return

	_start_attack()


func _start_attack() -> void:
	var weapon: Dictionary = get_current_weapon()
	attack_timer = float(weapon["cooldown"])
	attack_active_timer = attack_active_duration
	attack_flash_timer = attack_active_duration
	hit_targets.clear()
	attack_area.monitoring = true
	_update_attack_hitbox()
	_debug_attack_state("start")
	_apply_attack_hits(weapon)
	queue_redraw()


func _update_attack_state() -> void:
	if attack_active_timer <= 0.0:
		attack_area.monitoring = false
		return

	_update_attack_hitbox()
	_apply_attack_hits(get_current_weapon())


func _update_attack_hitbox() -> void:
	var rectangle := attack_shape.shape as RectangleShape2D
	if rectangle == null:
		return

	var weapon: Dictionary = get_current_weapon()
	var attack_start: float = _get_attack_start_distance()
	var attack_end: float = _get_attack_end_distance(weapon)
	rectangle.size = Vector2(attack_end - attack_start, _get_attack_full_width())
	attack_area.position = last_direction * ((attack_start + attack_end) * 0.5)
	attack_area.rotation = last_direction.angle()


func _apply_attack_hits(weapon: Dictionary) -> void:
	var attack_start: float = _get_attack_start_distance()
	var attack_end: float = _get_attack_end_distance(weapon)
	var attack_half_width: float = _get_attack_half_width()

	for body in get_tree().get_nodes_in_group("enemies"):
		if body == null or not is_instance_valid(body):
			continue
		if not body.has_method("take_damage"):
			continue

		var target_padding: float = _get_target_hit_padding(body) + 2.0
		var attack_space_position: Vector2 = _to_attack_space(_get_attack_target_position(body))
		if debug_attack or CombatDebug.enabled:
			print(
				"attack check %s forward=%.2f sideways=%.2f start=%.2f end=%.2f half=%.2f pad=%.2f"
				% [
					body.name,
					attack_space_position.x,
					absf(attack_space_position.y),
					attack_start,
					attack_end,
					attack_half_width,
					target_padding
				]
			)
		if not _is_inside_attack_window(attack_space_position, attack_start, attack_end, attack_half_width, target_padding):
			continue

		var instance_id: int = body.get_instance_id()
		if hit_targets.has(instance_id):
			continue

		hit_targets[instance_id] = true
		_debug_attack_state("hit %s" % body.name)
		body.take_damage(int(weapon["damage"]))


func _tick_timers(delta: float) -> void:
	if hit_timer > 0.0:
		hit_timer = maxf(hit_timer - delta, 0.0)

	if attack_timer > 0.0:
		attack_timer = maxf(attack_timer - delta, 0.0)

	if attack_active_timer > 0.0:
		attack_active_timer = maxf(attack_active_timer - delta, 0.0)

	if attack_flash_timer > 0.0:
		attack_flash_timer = maxf(attack_flash_timer - delta, 0.0)
		queue_redraw()


func _to_cardinal_direction(direction: Vector2) -> Vector2:
	if absf(direction.x) >= absf(direction.y):
		return Vector2.RIGHT if direction.x >= 0.0 else Vector2.LEFT
	return Vector2.DOWN if direction.y >= 0.0 else Vector2.UP


func _get_attack_visual_length(weapon: Dictionary) -> float:
	return maxf(float(weapon.get("range", attack_reach)), attack_reach)


func _get_attack_start_distance() -> float:
	return 8.0


func _get_attack_end_distance(weapon: Dictionary) -> float:
	return _get_attack_visual_length(weapon) + 12.0


func _get_attack_half_width() -> float:
	return maxf(attack_width * 0.5, 16.0)


func _get_attack_full_width() -> float:
	return _get_attack_half_width() * 2.0


func _debug_attack_state(event: String) -> void:
	if not debug_attack and not CombatDebug.enabled:
		return
	print("attack %s dir=%s hitbox=%s rot=%.2f" % [event, last_direction, attack_area.global_position, attack_area.global_rotation])


func _get_target_hit_padding(body: Node2D) -> float:
	for child in body.get_children():
		if child is CollisionShape2D:
			var shape: Shape2D = child.shape
			if shape is CircleShape2D:
				return (shape as CircleShape2D).radius
	return 10.0


func _get_attack_target_position(body: Node2D) -> Vector2:
	if body.has_method("get_attack_target_position"):
		return body.get_attack_target_position()
	return body.global_position


func _draw_debug_shapes() -> void:
	var hurt_shape := $CollisionShape2D.shape as CircleShape2D
	if hurt_shape != null:
		var hurt_center := _logic_to_local_screen(global_position)
		draw_arc(hurt_center, hurt_shape.radius, 0.0, TAU, 32, Color(1.0, 0.3, 0.3, 0.95), 2.0)

	var attack_polygon: PackedVector2Array = _get_attack_polygon()
	if attack_polygon.size() < 3:
		return

	var debug_color := Color(0.2, 0.85, 1.0, 0.95) if attack_active_timer > 0.0 else Color(0.2, 0.55, 0.9, 0.7)
	draw_polyline(PackedVector2Array([
		attack_polygon[0],
		attack_polygon[1],
		attack_polygon[2],
		attack_polygon[3],
		attack_polygon[0]
	]), debug_color, 2.0)


func refresh_combat_debug_draw() -> void:
	queue_redraw()
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Node2D:
			(node as Node2D).queue_redraw()


func _logic_to_local_screen(logic_position: Vector2) -> Vector2:
	return IsoMapper.logic_to_screen(logic_position, render_origin) - global_position


func _get_attack_polygon() -> PackedVector2Array:
	var weapon: Dictionary = get_current_weapon()
	var attack_start: float = _get_attack_start_distance()
	var attack_end: float = _get_attack_end_distance(weapon)
	var half_width: float = _get_attack_half_width()
	var forward: Vector2 = last_direction
	var sideways: Vector2 = Vector2(-forward.y, forward.x)
	var corners: Array[Vector2] = [
		global_position + forward * attack_start - sideways * half_width,
		global_position + forward * attack_start + sideways * half_width,
		global_position + forward * attack_end + sideways * half_width,
		global_position + forward * attack_end - sideways * half_width
	]

	var points: PackedVector2Array = []
	for corner in corners:
		points.append(_logic_to_local_screen(corner))
	return points


func _to_attack_space(logic_position: Vector2) -> Vector2:
	var delta: Vector2 = logic_position - global_position
	if absf(last_direction.x) > 0.0:
		return Vector2(delta.x * last_direction.x, delta.y)
	return Vector2(delta.y * last_direction.y, delta.x)


func _is_inside_attack_window(
	attack_space_position: Vector2,
	attack_start: float,
	attack_end: float,
	attack_half_width: float,
	target_padding: float
) -> bool:
	var forward: float = attack_space_position.x
	var sideways: float = absf(attack_space_position.y)
	return (
		forward + target_padding >= attack_start
		and forward - target_padding <= attack_end
		and sideways <= attack_half_width + target_padding
	)


func _get_render_offset() -> Vector2:
	return IsoMapper.render_offset(position, render_origin)
