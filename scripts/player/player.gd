extends CharacterBody2D

signal hp_changed(current_hp: int, max_hp: int)
signal weapon_changed(weapon_data)
signal died

const WeaponDB := preload("res://data/weapons/weapon_db.gd")
const IsoMapper := preload("res://scripts/core/iso.gd")
const CombatDebug := preload("res://scripts/core/combat_debug.gd")
const CharacterVisuals := preload("res://scripts/visual/character_visuals.gd")

@export var move_speed := 140.0
@export var max_hp := 12
@export var attack_reach := 32.0
@export var attack_width := 24.0
@export var attack_active_duration := 0.24
@export var attack_recovery_duration := 0.22
@export var attack_move_multiplier := 0.35
@export var sprint_move_multiplier := 1.75
@export var max_charge_duration := 0.8
@export var max_charge_bonus_range := 18.0
@export var charge_visual_scale_bonus := 0.08
@export var hit_pause_duration := 0.12
@export var hit_knockback_speed := 110.0
@export var hit_knockback_decay := 900.0
@export var movement_direction_hold_duration := 0.14
@export var debug_attack := false

var hp := max_hp
var control_enabled := true
var weapon_inventory: Dictionary = {}
var current_weapon = null
var has_amulet := false
var last_direction := Vector2.DOWN
var attack_direction := Vector2.DOWN
var movement_direction_hold_vector := Vector2.DOWN
var movement_direction_hold_timer := 0.0
var attack_timer := 0.0
var attack_active_timer := 0.0
var attack_recovery_timer := 0.0
var hit_timer := 0.0
var hit_stun_timer := 0.0
var attack_flash_timer := 0.0
var walk_anim_timer := 0.0
var death_visual_timer := 0.0
var charge_time := 0.0
var charging_attack := false
var attack_input_was_held := false
var current_attack_charge_ratio := 0.0
var current_attack_weapon: Dictionary = {}
var render_origin: Vector2 = Vector2.ZERO
var game: Node = null
var hit_targets: Dictionary = {}
var knockback_velocity: Vector2 = Vector2.ZERO

@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D


func _ready() -> void:
	reset_for_new_run()


func set_game_ref(game_ref: Node) -> void:
	game = game_ref


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	attack_direction = _get_attack_direction_from_input()

	_handle_attack_input(delta)

	if hit_stun_timer > 0.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, hit_knockback_decay * delta)
	elif control_enabled:
		_handle_movement()
		if attack_recovery_timer > 0.0:
			velocity *= attack_move_multiplier
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_update_walk_animation(delta)
	z_index = IsoMapper.entity_sort_z_for_foot(_get_sort_anchor_position())
	_update_attack_hitbox()
	_update_attack_state()


func _draw() -> void:
	var base: Vector2 = _get_render_offset()
	_draw_character_shadow(base)
	_draw_character_visual(base)

	var visual_direction: String = _get_visual_direction_id()
	if attack_flash_timer > 0.0 and not CharacterVisuals.has_state_texture("player", visual_direction, "attack"):
		var weapon: Dictionary = _get_active_attack_weapon()
		var tip_logic: Vector2 = position + attack_direction * _get_attack_visual_length(weapon)
		var tip: Vector2 = IsoMapper.logic_to_screen(tip_logic, render_origin) - position
		draw_line(CharacterVisuals.get_weapon_anchor("player", base), tip, weapon["color"], 4.0)

	if CombatDebug.enabled:
		_draw_debug_shapes()


func reset_for_new_run() -> void:
	hp = max_hp
	has_amulet = false
	weapon_inventory.clear()
	unlock_weapon(WeaponDB.get_default_weapon_id(), true)
	equip_weapon(WeaponDB.get_default_weapon_id())
	attack_timer = 0.0
	attack_active_timer = 0.0
	attack_recovery_timer = 0.0
	hit_timer = 0.0
	hit_stun_timer = 0.0
	attack_flash_timer = 0.0
	walk_anim_timer = 0.0
	death_visual_timer = 0.0
	charge_time = 0.0
	charging_attack = false
	attack_input_was_held = false
	current_attack_charge_ratio = 0.0
	current_attack_weapon.clear()
	control_enabled = true
	last_direction = Vector2.DOWN
	attack_direction = Vector2.DOWN
	movement_direction_hold_vector = Vector2.DOWN
	movement_direction_hold_timer = 0.0
	hit_targets.clear()
	knockback_velocity = Vector2.ZERO
	attack_area.monitoring = false
	emit_signal("hp_changed", hp, max_hp)
	queue_redraw()


func set_control_enabled(enabled: bool) -> void:
	control_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO


func set_render_origin(new_render_origin: Vector2) -> void:
	render_origin = new_render_origin
	z_index = IsoMapper.entity_sort_z_for_foot(_get_sort_anchor_position())
	queue_redraw()


func get_visual_position() -> Vector2:
	return IsoMapper.logic_to_screen(global_position, render_origin)


func get_debug_direction_info() -> Dictionary:
	var visual_state: String = _get_visual_state()
	var view_direction: Vector2 = _get_visual_direction_vector(visual_state)
	var attack_direction_vector: Vector2 = _get_debug_attack_direction_vector()
	return {
		"view_direction_id": CharacterVisuals.get_logic_direction_name_for_visual("player", view_direction, visual_state),
		"attack_direction_id": CharacterVisuals.get_logic_direction_name_for_visual("player", attack_direction_vector, "attack"),
		"view_direction_vector": view_direction,
		"attack_direction_vector": attack_direction_vector,
		"last_input_label": CombatDebug.last_input_label
	}


func unlock_weapon(weapon_id: String, silent: bool = false) -> bool:
	var weapon_data = WeaponDB.get_weapon(weapon_id)
	if weapon_data == null or weapon_inventory.has(weapon_data.id):
		return false

	weapon_inventory[weapon_data.id] = weapon_data
	if not silent:
		equip_weapon(weapon_data.id)
	return true


func equip_weapon(weapon_id: String) -> void:
	current_weapon = WeaponDB.get_weapon(weapon_id)
	emit_signal("weapon_changed", get_current_weapon())
	_update_attack_hitbox()
	queue_redraw()


func get_current_weapon():
	if current_weapon == null:
		current_weapon = WeaponDB.get_default_weapon()
	return current_weapon


func obtain_amulet() -> void:
	has_amulet = true


func clear_amulet() -> void:
	has_amulet = false


func heal(amount: int) -> int:
	var previous: int = hp
	hp = clampi(hp + amount, 0, max_hp)
	emit_signal("hp_changed", hp, max_hp)
	return hp - previous


func take_damage(amount: int, hit_direction: Vector2 = Vector2.ZERO, knockback_speed_override: float = -1.0) -> void:
	if hit_timer > 0.0 or hp <= 0:
		return

	hp = max(hp - amount, 0)
	if game != null and game.has_method("play_sfx"):
		game.play_sfx("player_hit")
	hit_timer = 0.45
	hit_stun_timer = hit_pause_duration
	var knockback_speed: float = hit_knockback_speed if knockback_speed_override < 0.0 else knockback_speed_override
	knockback_velocity = _get_knockback_direction(hit_direction) * knockback_speed
	attack_timer = maxf(attack_timer, 0.18)
	attack_active_timer = 0.0
	attack_recovery_timer = maxf(attack_recovery_timer, 0.12)
	_cancel_attack_charge()
	current_attack_weapon.clear()
	current_attack_charge_ratio = 0.0
	attack_area.monitoring = false
	emit_signal("hp_changed", hp, max_hp)
	queue_redraw()
	if hp <= 0:
		control_enabled = false
		death_visual_timer = 0.45
		emit_signal("died")


func _handle_movement() -> void:
	var move_input: Vector2 = _get_move_input_vector()
	var direction: Vector2 = Vector2(move_input.x, move_input.y)
	var normalized_direction: Vector2 = direction.normalized() if direction.length_squared() > 0.0 else Vector2.ZERO
	var movement_key_released: bool = _did_movement_input_release()

	if _is_mobile_platform():
		if normalized_direction.length_squared() > 0.0:
			last_direction = normalized_direction
			movement_direction_hold_vector = normalized_direction
		else:
			movement_direction_hold_vector = last_direction
		var speed_multiplier: float = sprint_move_multiplier if _is_sprinting() else 1.0
		velocity = normalized_direction * move_speed * speed_multiplier
		queue_redraw()
		return

	if normalized_direction.length_squared() > 0.0:
		if movement_direction_hold_timer <= 0.0 and movement_key_released and _is_diagonal_direction(last_direction) and not _is_diagonal_direction(normalized_direction):
			movement_direction_hold_vector = last_direction
			movement_direction_hold_timer = movement_direction_hold_duration
		elif movement_direction_hold_timer <= 0.0:
			last_direction = normalized_direction
			movement_direction_hold_vector = normalized_direction
	else:
		movement_direction_hold_vector = last_direction

	var speed_multiplier: float = sprint_move_multiplier if _is_sprinting() else 1.0
	velocity = normalized_direction * move_speed * speed_multiplier
	queue_redraw()


func _handle_attack_input(delta: float) -> void:
	var attack_pressed: bool = _get_attack_pressed()
	var attack_held: bool = _get_attack_held()

	if not control_enabled:
		_cancel_attack_charge()
		attack_input_was_held = attack_held
		return

	if _is_sprinting():
		_cancel_attack_charge()
		attack_input_was_held = attack_held
		return

	if attack_timer > 0.0 or attack_active_timer > 0.0 or attack_recovery_timer > 0.0 or hit_stun_timer > 0.0:
		if not attack_held:
			_cancel_attack_charge()
		attack_input_was_held = attack_held
		return

	if attack_pressed:
		charging_attack = true
		charge_time = 0.0
		queue_redraw()

	if not charging_attack:
		attack_input_was_held = attack_held
		return

	if attack_held:
		charge_time = minf(charge_time + delta, max_charge_duration)
		attack_input_was_held = attack_held
		queue_redraw()
		return

	if attack_input_was_held and not attack_held:
		_start_attack()
		attack_input_was_held = attack_held
		return

	_cancel_attack_charge()
	attack_input_was_held = attack_held


func _start_attack() -> void:
	current_attack_charge_ratio = _get_charge_ratio()
	current_attack_weapon = _build_attack_weapon(get_current_weapon(), current_attack_charge_ratio)
	if game != null and game.has_method("play_sfx"):
		game.play_sfx("attack")
	var weapon: Dictionary = _get_active_attack_weapon()
	var attack_cycle: float = _get_weapon_attack_cycle(weapon)
	attack_timer = attack_cycle
	attack_active_timer = attack_active_duration
	attack_recovery_timer = attack_cycle
	attack_flash_timer = attack_active_duration
	hit_targets.clear()
	attack_area.monitoring = true
	charging_attack = false
	charge_time = 0.0
	_update_attack_hitbox()
	_debug_attack_state("start")
	_apply_attack_hits(weapon)
	queue_redraw()


func _update_attack_state() -> void:
	if attack_active_timer <= 0.0:
		attack_area.monitoring = false
		return

	_update_attack_hitbox()
	_apply_attack_hits(_get_active_attack_weapon())


func _update_attack_hitbox() -> void:
	var circle := attack_shape.shape as CircleShape2D
	if circle == null:
		return

	var weapon: Dictionary = _get_active_attack_weapon()
	circle.radius = _get_attack_hit_radius(weapon)
	attack_area.position = attack_direction * _get_attack_center_distance(weapon)
	attack_area.rotation = 0.0


func _apply_attack_hits(weapon: Dictionary) -> void:
	var attack_center: Vector2 = global_position + attack_direction * _get_attack_center_distance(weapon)
	var attack_radius: float = _get_attack_hit_radius(weapon)

	for body in get_tree().get_nodes_in_group("enemies"):
		if body == null or not is_instance_valid(body):
			continue
		if not body.has_method("take_damage"):
			continue

		var target_padding: float = _get_target_hit_padding(body) + 2.0
		var target_position: Vector2 = _get_attack_target_position(body)
		var hit_distance: float = target_position.distance_to(attack_center)
		if debug_attack or CombatDebug.enabled:
			print(
				"attack check %s dist=%.2f radius=%.2f pad=%.2f center=%s dir=%s"
				% [
					body.name,
					hit_distance,
					attack_radius,
					target_padding,
					attack_center,
					attack_direction
				]
			)
		if hit_distance > attack_radius + target_padding:
			continue

		var instance_id: int = body.get_instance_id()
		if hit_targets.has(instance_id):
			continue

		hit_targets[instance_id] = true
		_debug_attack_state("hit %s" % body.name)
		body.take_damage(
			int(weapon["damage"]),
			attack_direction,
			float(weapon.get("knockback", 0.0)),
			float(weapon.get("stun_duration", 0.0)),
			current_attack_charge_ratio
		)

	for target in get_tree().get_nodes_in_group("player_attack_openables"):
		if target == null or not is_instance_valid(target):
			continue
		if not target.has_method("open_container"):
			continue

		var target_position: Vector2 = _get_attack_target_position(target)
		var target_padding: float = _get_target_hit_padding(target) + 2.0
		var hit_distance: float = target_position.distance_to(attack_center)
		if hit_distance > attack_radius + target_padding:
			continue

		var instance_id: int = target.get_instance_id()
		if hit_targets.has(instance_id):
			continue

		var opened_target: bool = target.open_container()
		if not opened_target:
			continue

		hit_targets[instance_id] = true
		_debug_attack_state("open %s" % target.name)


func _tick_timers(delta: float) -> void:
	if hit_timer > 0.0:
		hit_timer = maxf(hit_timer - delta, 0.0)

	if attack_timer > 0.0:
		attack_timer = maxf(attack_timer - delta, 0.0)

	if attack_active_timer > 0.0:
		attack_active_timer = maxf(attack_active_timer - delta, 0.0)

	if attack_recovery_timer > 0.0:
		attack_recovery_timer = maxf(attack_recovery_timer - delta, 0.0)

	if attack_flash_timer > 0.0:
		attack_flash_timer = maxf(attack_flash_timer - delta, 0.0)
		queue_redraw()

	if hit_stun_timer > 0.0:
		hit_stun_timer = maxf(hit_stun_timer - delta, 0.0)

	if movement_direction_hold_timer > 0.0:
		movement_direction_hold_timer = maxf(movement_direction_hold_timer - delta, 0.0)

	if death_visual_timer > 0.0:
		death_visual_timer = maxf(death_visual_timer - delta, 0.0)

	if attack_timer <= 0.0 and attack_active_timer <= 0.0 and attack_recovery_timer <= 0.0:
		current_attack_weapon.clear()
		current_attack_charge_ratio = 0.0


func _to_cardinal_direction(direction: Vector2) -> Vector2:
	if absf(direction.x) >= absf(direction.y):
		return Vector2.RIGHT if direction.x >= 0.0 else Vector2.LEFT
	return Vector2.DOWN if direction.y >= 0.0 else Vector2.UP


func _get_attack_visual_length(weapon: Dictionary) -> float:
	return maxf(float(weapon.get("attack_range", weapon.get("range", attack_reach))), attack_reach)


func _get_weapon_attack_cycle(weapon: Dictionary) -> float:
	return maxf(float(weapon.get("attack_speed", weapon.get("cooldown", attack_active_duration + attack_recovery_duration))), attack_active_duration + 0.06)


func _get_attack_center_distance(weapon: Dictionary) -> float:
	return _get_attack_visual_length(weapon)


func _get_attack_hit_radius(weapon: Dictionary) -> float:
	return maxf(float(weapon.get("attack_width", attack_width)) * 0.5, 14.0)


func _debug_attack_state(event: String) -> void:
	if not debug_attack and not CombatDebug.enabled:
		return
	print("attack %s dir=%s hitbox=%s rot=%.2f" % [event, attack_direction, attack_area.global_position, attack_area.global_rotation])


func _get_knockback_direction(hit_direction: Vector2) -> Vector2:
	if hit_direction.length_squared() > 0.0:
		return hit_direction.normalized()
	if last_direction.length_squared() > 0.0:
		return -last_direction.normalized()
	return Vector2.UP


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
	if attack_polygon.is_empty():
		return

	var weapon: Dictionary = _get_active_attack_weapon()
	var debug_color := Color(0.2, 0.85, 1.0, 0.95) if attack_active_timer > 0.0 else Color(0.2, 0.55, 0.9, 0.7)
	draw_arc(attack_polygon[0], _get_attack_hit_radius(weapon), 0.0, TAU, 32, debug_color, 2.0)
	draw_line(_logic_to_local_screen(global_position), attack_polygon[0], debug_color, 2.0)


func refresh_combat_debug_draw() -> void:
	queue_redraw()
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Node2D:
			(node as Node2D).queue_redraw()


func refresh_direction_debug_draw() -> void:
	queue_redraw()


func _logic_to_local_screen(logic_position: Vector2) -> Vector2:
	return IsoMapper.logic_to_screen(logic_position, render_origin) - global_position


func _get_attack_polygon() -> PackedVector2Array:
	return PackedVector2Array([
		_logic_to_local_screen(global_position + attack_direction * _get_attack_center_distance(_get_active_attack_weapon()))
	])


func _get_render_offset() -> Vector2:
	return IsoMapper.render_offset(position, render_origin)


func _get_sort_anchor_position() -> Vector2:
	return global_position


func _draw_character_shadow(base: Vector2) -> void:
	var shadow_rect: Rect2 = CharacterVisuals.get_shadow_rect("player", base)
	if charging_attack:
		var shadow_scale: float = 1.0 + _get_charge_ratio() * 0.04
		shadow_rect = _scale_rect_from_bottom_center(shadow_rect, shadow_scale)
	draw_rect(shadow_rect, Color(0, 0, 0, 0.18))


func _draw_character_visual(base: Vector2) -> void:
	var visual_state: String = _get_visual_state()
	var visual_direction: String = _get_visual_direction_id(visual_state)
	var visual_frame_id: String = _get_visual_frame_id(visual_state)
	var texture_data: Dictionary = CharacterVisuals.get_state_texture_draw_data("player", visual_direction, visual_state, base, visual_frame_id)
	if debug_attack or CombatDebug.enabled:
		print(
			"STATE:",
			visual_state,
			"DIR:",
			visual_direction,
			"PLAY:",
			texture_data.get("animation_frame_name", CharacterVisuals.get_animation_frame_name(visual_state, visual_direction, visual_frame_id))
		)
	var texture: Texture2D = texture_data.get("texture", null)
	if texture == null:
		return

	var modulate: Color = Color.WHITE
	if hit_timer > 0.0:
		modulate = Color(1.0, 0.76, 0.76, 1.0)
	var draw_rect: Rect2 = texture_data.get("draw_rect", Rect2())
	if charging_attack:
		draw_rect = _scale_rect_from_bottom_center(draw_rect, 1.0 + _get_charge_ratio() * charge_visual_scale_bonus)
	draw_texture_rect_region(texture, draw_rect, texture_data.get("source_rect", Rect2(Vector2.ZERO, texture.get_size())), modulate, false, true)
	if CombatDebug.direction_overlay_enabled:
		_draw_direction_debug_arrows(draw_rect)


func _get_visual_state() -> String:
	if hp <= 0 or death_visual_timer > 0.0:
		return "death"
	if hit_stun_timer > 0.0 or hit_timer > 0.0:
		return "hit"
	if _is_attack_visual_state():
		return "attack"
	if velocity.length() > 5.0:
		return "walk"
	return "idle"


func _get_visual_direction_id(visual_state: String = "") -> String:
	if visual_state.is_empty():
		visual_state = _get_visual_state()
	return CharacterVisuals.get_logic_direction_name_for_visual("player", _get_visual_direction_vector(visual_state), visual_state)


func _get_visual_direction_vector(visual_state: String = "") -> Vector2:
	if visual_state.is_empty():
		visual_state = _get_visual_state()

	if visual_state == "attack":
		return _get_aim_direction_vector()
	return _get_movement_direction_vector()


func _get_visual_frame_id(visual_state: String) -> String:
	if visual_state != "walk":
		return ""
	return "1" if int(floor(walk_anim_timer * 7.0)) % 2 == 0 else "2"


func _update_walk_animation(delta: float) -> void:
	if _get_visual_state() == "walk":
		walk_anim_timer += delta
		return
	walk_anim_timer = 0.0


func _is_attack_visual_state() -> bool:
	return attack_active_timer > 0.0 or charging_attack


func _get_attack_direction_from_mouse() -> Vector2:
	var mouse_logic: Vector2 = IsoMapper.screen_to_logic(get_global_mouse_position(), render_origin)
	var direction: Vector2 = mouse_logic - global_position
	if direction.length_squared() > 0.001:
		return direction.normalized()
	if last_direction.length_squared() > 0.001:
		return last_direction.normalized()
	return Vector2.DOWN


func _get_attack_direction_from_input() -> Vector2:
	if game != null and game.has_method("get_aim_vector"):
		var aim_direction: Vector2 = game.get_aim_vector(global_position, render_origin)
		if aim_direction.length_squared() > 0.001:
			return aim_direction.normalized()
		if _is_mobile_platform():
			if last_direction.length_squared() > 0.001:
				return last_direction.normalized()
			return Vector2.DOWN
	return _get_attack_direction_from_mouse()


func _get_move_input_vector() -> Vector2:
	if game != null and game.has_method("get_move_vector"):
		return game.get_move_vector()
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)


func _get_attack_pressed() -> bool:
	if game != null and game.has_method("get_attack_pressed"):
		return game.get_attack_pressed()
	return Input.is_action_just_pressed("attack")


func _get_attack_held() -> bool:
	if game != null and game.has_method("get_attack_held"):
		return game.get_attack_held()
	return Input.is_action_pressed("attack")


func _did_movement_input_release() -> bool:
	if game != null and game.has_method("is_mobile_platform") and game.is_mobile_platform():
		return false
	return Input.is_action_just_released("move_up") or Input.is_action_just_released("move_down") or Input.is_action_just_released("move_left") or Input.is_action_just_released("move_right")


func _get_movement_direction_vector() -> Vector2:
	if movement_direction_hold_timer > 0.0 and movement_direction_hold_vector.length_squared() > 0.001:
		return movement_direction_hold_vector.normalized()
	if velocity.length_squared() > 0.001:
		return velocity.normalized()
	if last_direction.length_squared() > 0.001:
		return last_direction.normalized()
	return Vector2.DOWN


func _get_aim_direction_vector() -> Vector2:
	if attack_direction.length_squared() > 0.001:
		return attack_direction.normalized()
	return _get_attack_direction_from_mouse()


func _is_sprinting() -> bool:
	if _is_mobile_platform():
		return false
	return Input.is_key_pressed(KEY_SHIFT)


func _is_mobile_platform() -> bool:
	return game != null and game.has_method("is_mobile_platform") and game.is_mobile_platform()


func _is_diagonal_direction(direction: Vector2) -> bool:
	return absf(direction.x) > 0.001 and absf(direction.y) > 0.001


func _build_attack_weapon(base_weapon, charge_ratio: float) -> Dictionary:
	var charged_weapon: Dictionary = _weapon_data_to_attack_stats(base_weapon)
	charged_weapon["damage"] = maxi(int(round(float(base_weapon.damage) * (1.0 + charge_ratio))), 1)
	charged_weapon["attack_range"] = float(base_weapon.attack_range) + charge_ratio * max_charge_bonus_range
	charged_weapon["knockback"] = float(base_weapon.knockback) * (1.0 + charge_ratio * 1.5)
	return charged_weapon


func _get_active_attack_weapon() -> Dictionary:
	if not current_attack_weapon.is_empty():
		return current_attack_weapon
	return _weapon_data_to_attack_stats(get_current_weapon())


func _weapon_data_to_attack_stats(weapon_data) -> Dictionary:
	if weapon_data == null:
		weapon_data = WeaponDB.get_default_weapon()
	return {
		"id": weapon_data.id,
		"display_name": weapon_data.display_name,
		"damage": weapon_data.damage,
		"attack_range": weapon_data.attack_range,
		"attack_speed": weapon_data.attack_speed,
		"attack_width": weapon_data.attack_width,
		"knockback": weapon_data.knockback,
		"stun_duration": weapon_data.stun_duration,
		"color": weapon_data.color
	}


func _get_charge_ratio() -> float:
	if max_charge_duration <= 0.0:
		return 0.0
	return clampf(charge_time / max_charge_duration, 0.0, 1.0)


func _cancel_attack_charge() -> void:
	if not charging_attack and is_zero_approx(charge_time):
		return
	charging_attack = false
	charge_time = 0.0
	attack_input_was_held = false
	queue_redraw()


func _scale_rect_from_bottom_center(rect: Rect2, scale_factor: float) -> Rect2:
	var scaled_size: Vector2 = rect.size * scale_factor
	return Rect2(
		Vector2(
			rect.position.x + (rect.size.x - scaled_size.x) * 0.5,
			rect.position.y + rect.size.y - scaled_size.y
		),
		scaled_size
	)


func _get_debug_attack_direction_vector() -> Vector2:
	if attack_direction.length_squared() > 0.001:
		return attack_direction.normalized()
	if last_direction.length_squared() > 0.001:
		return last_direction.normalized()
	return Vector2.DOWN


func _draw_direction_debug_arrows(character_rect: Rect2) -> void:
	var debug_rect: Rect2 = character_rect.grow(2.0)
	var center: Vector2 = debug_rect.get_center()
	var reach: float = maxf(debug_rect.size.x, debug_rect.size.y) * 0.5 + 14.0
	var view_direction: Vector2 = _get_visual_direction_vector()
	var attack_direction_vector: Vector2 = _get_debug_attack_direction_vector()
	var view_screen_direction: Vector2 = IsoMapper.logic_direction_to_screen(view_direction)
	var attack_screen_direction: Vector2 = IsoMapper.logic_direction_to_screen(attack_direction_vector)
	var view_origin: Vector2 = center + view_screen_direction * reach
	var attack_origin: Vector2 = center + attack_screen_direction * (reach + 8.0)
	_draw_debug_arrow(view_origin, view_screen_direction, Color(0.2, 0.62, 1.0, 0.95), 40.0, 8.0)
	_draw_debug_arrow(attack_origin, attack_screen_direction, Color(1.0, 0.25, 0.3, 0.95), 34.0, 8.5)


func _draw_debug_arrow(origin: Vector2, direction: Vector2, color: Color, length: float, line_width: float) -> void:
	if direction.length_squared() <= 0.001:
		return

	var dir: Vector2 = direction.normalized()
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	var shaft_length: float = length * 0.68
	var shaft_end: Vector2 = origin + dir * shaft_length
	var tip: Vector2 = origin + dir * length
	var head_half_width: float = line_width * 1.25
	var outline_expand: float = 1.75
	var outline_head := PackedVector2Array([
		shaft_end + perp * (head_half_width + outline_expand),
		tip + dir * outline_expand,
		shaft_end - perp * (head_half_width + outline_expand)
	])
	var head := PackedVector2Array([
		shaft_end + perp * head_half_width,
		tip,
		shaft_end - perp * head_half_width
	])
	draw_line(origin, shaft_end, Color(0, 0, 0, 0.45), line_width + 3.0, true)
	draw_colored_polygon(outline_head, Color(0, 0, 0, 0.45))
	draw_line(origin, shaft_end, color, line_width, true)
	draw_colored_polygon(head, color)


func get_attack_charge_ratio() -> float:
	return _get_charge_ratio() if charging_attack else 0.0


func get_attack_feedback_ratio() -> float:
	if attack_active_duration <= 0.0:
		return 0.0
	return clampf(attack_flash_timer / attack_active_duration, 0.0, 1.0)
