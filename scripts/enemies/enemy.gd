extends CharacterBody2D

signal defeated(enemy: Node, drop_data: Dictionary)
signal engagement_changed(enemy: Node, engaged: bool)

const IsoMapper := preload("res://scripts/core/iso.gd")
const CombatDebug := preload("res://scripts/core/combat_debug.gd")
const CharacterVisuals := preload("res://scripts/visual/character_visuals.gd")

const STOP_DISTANCE_BUFFER := 8.0
const ENEMY_HIT_PAUSE := 0.14
const ENEMY_HIT_KNOCKBACK_SPEED := 78.0
const ENEMY_HIT_KNOCKBACK_DECAY := 620.0
const CLOSE_STRAFE_FACTOR := 0.42
const PATH_REFRESH_INTERVAL := 0.32
const PATH_WAYPOINT_REACHED_DISTANCE := 10.0
const PATH_LOOKAHEAD_STEPS := 4

const STATS := {
	"zombie": {
		"display_name": "Zombie",
		"speed": 48.0,
		"max_hp": 7,
		"damage": 3,
		"chase_range": 240.0,
		"melee_range": 26.0,
		"attack_cooldown": 1.3,
		"attack_windup": 0.32,
		"player_knockback_speed": 185.0,
		"received_knockback_speed": 56.0,
		"orbit_strength": 0.05,
		"close_orbit_bonus": 0.08,
		"strafe_factor": 0.18,
		"body_color": Color8(97, 141, 92),
		"head_color": Color8(141, 168, 100),
		"size": Vector2(24, 24)
	},
	"skeleton": {
		"display_name": "Skelett",
		"speed": 76.0,
		"max_hp": 5,
		"damage": 2,
		"chase_range": 280.0,
		"melee_range": 42.0,
		"attack_cooldown": 0.82,
		"attack_windup": 0.18,
		"player_knockback_speed": 95.0,
		"received_knockback_speed": 88.0,
		"orbit_strength": 0.22,
		"close_orbit_bonus": 0.4,
		"strafe_factor": 0.56,
		"lunge_distance": 12.0,
		"weapon_length": 20.0,
		"weapon_color": Color8(209, 218, 232),
		"body_color": Color8(203, 203, 186),
		"head_color": Color8(241, 231, 203),
		"size": Vector2(18, 22)
	},
	"strawman": {
		"display_name": "Strohpupe",
		"speed": 0.0,
		"max_hp": 50,
		"damage": 0,
		"chase_range": 0.0,
		"melee_range": 0.0,
		"attack_cooldown": 999.0,
		"body_color": Color8(240, 212, 74),
		"head_color": Color8(255, 235, 130),
		"size": Vector2(22, 28)
	},
	"boss": {
		"display_name": "Abyss-Waechter",
		"speed": 58.0,
		"max_hp": 20,
		"damage": 3,
		"chase_range": 340.0,
		"melee_range": 36.0,
		"attack_cooldown": 1.1,
		"body_color": Color8(85, 48, 42),
		"head_color": Color8(223, 115, 73),
		"size": Vector2(32, 32),
		"slam_radius": 96.0,
		"slam_damage": 3,
		"slam_cooldown": 4.2,
		"slam_windup": 0.8
	}
}

var enemy_type: String = "zombie"
var game: Node = null
var player: Node = null
var drop_data: Dictionary = {}
var stats: Dictionary = STATS["zombie"]
var hp: int = 5
var active: bool = true
var attack_timer: float = 0.0
var attack_windup_timer: float = 0.0
var hit_pause_timer: float = 0.0
var hit_flash_timer: float = 0.0
var slam_timer: float = 0.0
var slam_charge: float = 0.0
var render_origin: Vector2 = Vector2.ZERO
var _engaged: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var orbit_sign: float = 1.0
var orbit_strength: float = 0.22
var facing_direction: Vector2 = Vector2.DOWN
var current_level: Node = null
var navigation_path: Array = []
var navigation_path_index: int = 0
var navigation_refresh_timer: float = 0.0
var navigation_target_tile: Vector2i = Vector2i(-9999, -9999)


func setup(type_name: String, game_ref: Node, extra_data: Dictionary = {}) -> void:
	enemy_type = type_name
	stats = STATS.get(enemy_type, STATS["zombie"]).duplicate(true)
	game = game_ref
	player = game.get_player()
	current_level = game.get_current_level() if game != null and game.has_method("get_current_level") else null
	hp = stats["max_hp"]
	drop_data = extra_data.get("drop", {})
	orbit_sign = -1.0 if (int(global_position.x / IsoMapper.LOGIC_TILE_SIZE) + int(global_position.y / IsoMapper.LOGIC_TILE_SIZE)) % 2 == 0 else 1.0
	orbit_strength = float(stats.get("orbit_strength", 0.18)) + float((int(global_position.x / IsoMapper.LOGIC_TILE_SIZE) + int(global_position.y / IsoMapper.LOGIC_TILE_SIZE)) % 3) * 0.03
	scale = Vector2.ONE
	if enemy_type == "strawman":
		collision_layer = 0
		collision_mask = 0
		active = false
		velocity = Vector2.ZERO
		queue_redraw()
		return
	if enemy_type == "boss":
		var collision: CircleShape2D = $CollisionShape2D.shape as CircleShape2D
		collision.radius = 18.0
	else:
		var collision: CircleShape2D = $CollisionShape2D.shape as CircleShape2D
		collision.radius = 12.0
	queue_redraw()


func set_active(value: bool) -> void:
	active = value
	if not active:
		velocity = Vector2.ZERO
		_clear_navigation_path()


func set_render_origin(new_render_origin: Vector2) -> void:
	render_origin = new_render_origin
	z_index = IsoMapper.entity_sort_z_for_foot(_get_sort_anchor_position())
	queue_redraw()


func _physics_process(delta: float) -> void:
	var previous_position: Vector2 = global_position

	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		queue_redraw()

	if current_level == null or not is_instance_valid(current_level):
		current_level = game.get_current_level() if game != null and game.has_method("get_current_level") else null

	if not CombatDebug.enemy_logic_enabled:
		_set_engaged(false)
		velocity = Vector2.ZERO
		_clear_navigation_path()
		move_and_slide()
		_queue_redraw_if_moved(previous_position)
		return

	if attack_timer > 0.0:
		attack_timer -= delta

	if hit_pause_timer > 0.0:
		hit_pause_timer = maxf(hit_pause_timer - delta, 0.0)
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, ENEMY_HIT_KNOCKBACK_DECAY * delta)
		move_and_slide()
		z_index = IsoMapper.entity_sort_z_for_foot(_get_sort_anchor_position())
		_queue_redraw_if_moved(previous_position)
		return

	if slam_timer > 0.0:
		slam_timer -= delta

	if slam_charge > 0.0:
		slam_charge -= delta
		queue_redraw()
		if slam_charge <= 0.0:
			_resolve_slam()

	if not active or player == null or not is_instance_valid(player):
		_set_engaged(false)
		velocity = Vector2.ZERO
		_clear_navigation_path()
		move_and_slide()
		_queue_redraw_if_moved(previous_position)
		return

	var to_player: Vector2 = player.global_position - global_position
	var distance: float = to_player.length()
	if to_player.length_squared() > 0.001:
		facing_direction = _get_facing_direction(to_player)
	if distance > stats["chase_range"]:
		_set_engaged(false)
		velocity = Vector2.ZERO
		_clear_navigation_path()
		move_and_slide()
		_queue_redraw_if_moved(previous_position)
		return

	_set_engaged(true)

	var attack_distance: float = _get_attack_distance()
	var stop_distance: float = attack_distance + STOP_DISTANCE_BUFFER

	if attack_windup_timer > 0.0:
		attack_windup_timer = maxf(attack_windup_timer - delta, 0.0)
		velocity = Vector2.ZERO
		if attack_windup_timer <= 0.0:
			_resolve_melee_attack()
		move_and_slide()
		z_index = IsoMapper.entity_sort_z_for_foot(_get_sort_anchor_position())
		_queue_redraw_if_moved(previous_position)
		return

	if enemy_type == "boss" and slam_timer <= 0.0 and slam_charge <= 0.0 and distance < 150.0:
		slam_charge = stats["slam_windup"]
		slam_timer = stats["slam_cooldown"]
		velocity = Vector2.ZERO
		move_and_slide()
		_queue_redraw_if_moved(previous_position)
		return

	if distance > stop_distance:
		velocity = _get_navigation_direction(delta, to_player, false) * stats["speed"]
	elif distance > attack_distance:
		velocity = _get_navigation_direction(delta, to_player, true) * stats["speed"] * 0.72
	else:
		_clear_navigation_path()
		if attack_timer <= 0.0:
			attack_timer = stats["attack_cooldown"]
			attack_windup_timer = _get_attack_windup_duration()
			velocity = Vector2.ZERO
			queue_redraw()
		else:
			velocity = _get_strafe_direction(to_player) * stats["speed"] * _get_strafe_speed_factor()
	move_and_slide()
	if velocity.length_squared() > 1.0 and global_position.distance_squared_to(previous_position) < 0.5:
		navigation_refresh_timer = 0.0
	z_index = IsoMapper.entity_sort_z_for_foot(_get_sort_anchor_position())
	_queue_redraw_if_moved(previous_position)




func _exit_tree() -> void:
	_set_engaged(false)


func _set_engaged(value: bool) -> void:
	if _engaged == value:
		return
	_engaged = value
	emit_signal("engagement_changed", self, _engaged)


func _draw() -> void:
	var base: Vector2 = _get_render_offset()
	var size: Vector2 = CharacterVisuals.get_visual_size(enemy_type) if CharacterVisuals.has_visual(enemy_type) else stats["size"]
	var width: float = size.x
	var height: float = size.y
	_draw_hp_bar(base, width, height)
	_draw_character_shadow(base)
	if CharacterVisuals.has_visual(enemy_type):
		_draw_character_visual(base)
	elif enemy_type == "skeleton":
		var body_color: Color = stats["body_color"]
		var head_color: Color = stats["head_color"]
		if hit_flash_timer > 0.0:
			body_color = Color8(255, 128, 128)
			head_color = Color8(255, 206, 206)
		draw_rect(Rect2(base + Vector2(-width * 0.45, height * 0.35), Vector2(width * 0.9, 8)), Color(0, 0, 0, 0.18))
		draw_rect(Rect2(base + Vector2(-width * 0.45, -height * 0.1), Vector2(width * 0.9, height * 0.55)), body_color)
		draw_rect(Rect2(base + Vector2(-width * 0.3, -height * 0.45), Vector2(width * 0.6, height * 0.35)), head_color)
		_draw_weapon(base, width, height)
	else:
		var body_color: Color = stats["body_color"]
		var head_color: Color = stats["head_color"]
		if hit_flash_timer > 0.0:
			body_color = Color8(255, 128, 128)
			head_color = Color8(255, 206, 206)
		draw_rect(Rect2(base + Vector2(-width * 0.45, height * 0.35), Vector2(width * 0.9, 8)), Color(0, 0, 0, 0.18))
		draw_rect(Rect2(base + Vector2(-width * 0.45, -height * 0.1), Vector2(width * 0.9, height * 0.55)), body_color)
		draw_rect(Rect2(base + Vector2(-width * 0.3, -height * 0.45), Vector2(width * 0.6, height * 0.35)), head_color)

	if attack_windup_timer > 0.0:
		var telegraph_color: Color = Color8(255, 166, 73) if enemy_type != "zombie" else Color8(255, 118, 79)
		draw_arc(base + Vector2(0.0, height * 0.05), maxf(width * 0.55, 10.0), 0.0, TAU, 24, telegraph_color, 2.0)

	if enemy_type == "boss" and slam_charge > 0.0:
		var radius: float = float(stats["slam_radius"]) * (1.0 - slam_charge / float(stats["slam_windup"]))
		draw_arc(base, max(radius, 12.0), 0.0, TAU, 48, Color8(255, 128, 80), 4.0)

	if CombatDebug.enabled:
		_draw_debug_hurtbox()


func take_damage(amount: int, hit_direction: Vector2 = Vector2.ZERO) -> void:
	if hp <= 0:
		return

	hp = max(hp - amount, 0)
	hit_flash_timer = 0.16
	attack_windup_timer = 0.0
	if enemy_type != "strawman":
		hit_pause_timer = ENEMY_HIT_PAUSE if enemy_type != "boss" else 0.1
		knockback_velocity = _get_hit_knockback_direction(hit_direction) * _get_hit_knockback_speed()
		attack_timer = maxf(attack_timer, 0.18)
	queue_redraw()
	if hp <= 0:
		emit_signal("defeated", self, drop_data)
		queue_free()


func _resolve_slam() -> void:
	if player == null or not is_instance_valid(player):
		return

	if global_position.distance_to(player.global_position) <= stats["slam_radius"]:
		player.take_damage(stats["slam_damage"], (player.global_position - global_position).normalized(), 140.0)


func _get_render_offset() -> Vector2:
	return IsoMapper.render_offset(position, render_origin)


func _draw_hp_bar(base: Vector2, width: float, height: float) -> void:
	var max_hp_value: int = int(stats["max_hp"])
	if max_hp_value <= 0:
		return

	var bar_width: float = max(width + 6.0, 24.0)
	var bar_height: float = 5.0 if enemy_type != "boss" else 7.0
	var bar_position := base + Vector2(-bar_width * 0.5, -height * 0.65 - bar_height - 6.0)
	var fill_ratio: float = clampf(float(hp) / float(max_hp_value), 0.0, 1.0)
	var fill_color: Color = Color8(96, 207, 92) if enemy_type != "boss" else Color8(232, 111, 71)

	draw_rect(Rect2(bar_position + Vector2(1, 1), Vector2(bar_width, bar_height)), Color(0, 0, 0, 0.2))
	draw_rect(Rect2(bar_position, Vector2(bar_width, bar_height)), Color8(38, 38, 38))
	draw_rect(Rect2(bar_position + Vector2(1, 1), Vector2((bar_width - 2.0) * fill_ratio, bar_height - 2.0)), fill_color)


func _draw_weapon(base: Vector2, width: float, height: float) -> void:
	var weapon_length: float = float(stats.get("weapon_length", 0.0))
	if weapon_length <= 0.0:
		return

	var hand: Vector2 = base + Vector2(width * 0.12, -height * 0.02)
	var blade_delta: Vector2 = _logic_vector_to_local_screen_delta(facing_direction * weapon_length)
	if attack_windup_timer > 0.0:
		blade_delta *= 1.18
	var weapon_color: Color = stats.get("weapon_color", Color8(209, 218, 232))
	draw_line(hand, hand + blade_delta, weapon_color, 3.0)
	draw_circle(hand, 2.0, Color8(126, 88, 53))


func _draw_debug_hurtbox() -> void:
	var hurt_shape := $CollisionShape2D.shape as CircleShape2D
	if hurt_shape == null:
		return
	var hurt_center := IsoMapper.logic_to_screen(global_position, render_origin) - global_position
	draw_arc(hurt_center, hurt_shape.radius, 0.0, TAU, 32, Color(1.0, 0.1, 0.9, 0.95), 2.0)
	for point in get_hit_test_screen_points():
		var local_point: Vector2 = point - global_position
		draw_circle(local_point, 3.0, Color(1.0, 0.8, 0.1, 0.95))


func get_hit_test_screen_points() -> PackedVector2Array:
	var base: Vector2 = IsoMapper.logic_to_screen(global_position, render_origin)
	var size: Vector2 = CharacterVisuals.get_visual_size(enemy_type) if CharacterVisuals.has_visual(enemy_type) else stats["size"]
	return PackedVector2Array([
		base + Vector2(0.0, -size.y * 0.1),
		base + Vector2(0.0, -size.y * 0.42),
		base + Vector2(0.0, -size.y * 0.72)
	])


func get_attack_target_position() -> Vector2:
	if active and CombatDebug.enemy_logic_enabled and velocity.length_squared() > 0.0:
		return global_position + velocity * get_physics_process_delta_time()
	return global_position


func _resolve_melee_attack() -> void:
	if player == null or not is_instance_valid(player):
		return

	var to_player: Vector2 = player.global_position - global_position
	var attack_direction: Vector2 = _get_facing_direction(to_player)
	_perform_attack_lunge(attack_direction, to_player.length())
	to_player = player.global_position - global_position
	if to_player.length() > _get_attack_distance():
		queue_redraw()
		return

	player.take_damage(stats["damage"], attack_direction, _get_player_knockback_speed())
	queue_redraw()


func _get_attack_distance() -> float:
	return maxf(float(stats["melee_range"]), _get_player_contact_distance())


func _get_attack_windup_duration() -> float:
	return float(stats.get("attack_windup", 0.24))


func _get_navigation_direction(delta: float, to_player: Vector2, close_mode: bool) -> Vector2:
	var default_direction: Vector2 = _get_close_combat_direction(to_player) if close_mode else _get_approach_direction(to_player)
	if current_level == null or not is_instance_valid(current_level):
		return default_direction
	if not current_level.has_method("world_to_tile") or not current_level.has_method("get_navigation_path_tiles"):
		return default_direction

	var from_tile: Vector2i = current_level.world_to_tile(global_position)
	var target_tile: Vector2i = current_level.world_to_tile(player.global_position)
	if current_level.has_method("has_clear_tile_line") and current_level.has_clear_tile_line(from_tile, target_tile):
		_clear_navigation_path()
		return default_direction

	_update_navigation_path(delta, target_tile)
	var path_direction: Vector2 = _get_navigation_path_direction(from_tile)
	if path_direction.length_squared() <= 0.001:
		return default_direction

	var path_weight: float = 0.7 if close_mode else 0.82
	return (path_direction * path_weight + default_direction * (1.0 - path_weight)).normalized()


func _update_navigation_path(delta: float, target_tile: Vector2i) -> void:
	navigation_refresh_timer = maxf(navigation_refresh_timer - delta, 0.0)
	var needs_refresh: bool = navigation_path.is_empty() or navigation_refresh_timer <= 0.0 or target_tile != navigation_target_tile
	if not needs_refresh:
		return

	navigation_refresh_timer = PATH_REFRESH_INTERVAL
	navigation_target_tile = target_tile
	navigation_path = current_level.get_navigation_path_tiles(global_position, player.global_position)
	navigation_path_index = 1 if navigation_path.size() > 1 else 0


func _get_navigation_path_direction(from_tile: Vector2i) -> Vector2:
	if navigation_path.is_empty():
		return Vector2.ZERO

	while navigation_path_index < navigation_path.size():
		var waypoint_world: Vector2 = current_level.tile_to_world(navigation_path[navigation_path_index])
		if global_position.distance_to(waypoint_world) > PATH_WAYPOINT_REACHED_DISTANCE:
			break
		navigation_path_index += 1

	if navigation_path_index >= navigation_path.size():
		return Vector2.ZERO

	var furthest_visible_index: int = navigation_path_index
	if current_level.has_method("has_clear_tile_line"):
		var end_index: int = mini(navigation_path_index + PATH_LOOKAHEAD_STEPS, navigation_path.size() - 1)
		for i in range(navigation_path_index, end_index + 1):
			if current_level.has_clear_tile_line(from_tile, navigation_path[i]):
				furthest_visible_index = i
			else:
				break
	navigation_path_index = furthest_visible_index

	var target_world: Vector2 = current_level.tile_to_world(navigation_path[navigation_path_index])
	return (target_world - global_position).normalized()


func _clear_navigation_path() -> void:
	navigation_path.clear()
	navigation_path_index = 0
	navigation_refresh_timer = 0.0
	navigation_target_tile = Vector2i(-9999, -9999)


func _get_approach_direction(to_player: Vector2) -> Vector2:
	var forward: Vector2 = to_player.normalized()
	var tangent: Vector2 = Vector2(-forward.y, forward.x) * orbit_sign
	return (forward + tangent * orbit_strength).normalized()


func _get_close_combat_direction(to_player: Vector2) -> Vector2:
	var forward: Vector2 = to_player.normalized()
	var tangent: Vector2 = Vector2(-forward.y, forward.x) * orbit_sign
	return (forward * 0.8 + tangent * (orbit_strength + float(stats.get("close_orbit_bonus", 0.28)))).normalized()


func _get_strafe_direction(to_player: Vector2) -> Vector2:
	var forward: Vector2 = to_player.normalized()
	var tangent: Vector2 = Vector2(-forward.y, forward.x) * orbit_sign
	var strafe: Vector2 = tangent - forward * 0.2
	if strafe.length_squared() <= 0.001:
		return tangent
	return strafe.normalized()


func _get_strafe_speed_factor() -> float:
	return float(stats.get("strafe_factor", CLOSE_STRAFE_FACTOR))


func _perform_attack_lunge(attack_direction: Vector2, current_distance: float) -> void:
	var lunge_distance: float = float(stats.get("lunge_distance", 0.0))
	if lunge_distance <= 0.0 or attack_direction.length_squared() <= 0.001:
		return

	var open_distance: float = maxf(current_distance - _get_player_contact_distance() + 4.0, 0.0)
	var actual_lunge: float = minf(lunge_distance, open_distance)
	if actual_lunge <= 0.0:
		return

	move_and_collide(attack_direction.normalized() * actual_lunge)


func _get_facing_direction(direction: Vector2) -> Vector2:
	if direction.length_squared() <= 0.001:
		return facing_direction
	return _to_cardinal_direction(direction)


func _to_cardinal_direction(direction: Vector2) -> Vector2:
	if absf(direction.x) > absf(direction.y):
		return Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if direction.y > 0.0 else Vector2.UP


func _logic_vector_to_local_screen_delta(logic_vector: Vector2) -> Vector2:
	var origin_screen: Vector2 = IsoMapper.logic_to_screen(global_position, render_origin) - global_position
	var target_screen: Vector2 = IsoMapper.logic_to_screen(global_position + logic_vector, render_origin) - global_position
	return target_screen - origin_screen


func _get_hit_knockback_direction(hit_direction: Vector2) -> Vector2:
	if hit_direction.length_squared() > 0.0:
		return hit_direction.normalized()
	if player != null and is_instance_valid(player):
		return (global_position - player.global_position).normalized()
	return Vector2.UP


func _get_hit_knockback_speed() -> float:
	if enemy_type == "boss":
		return ENEMY_HIT_KNOCKBACK_SPEED * 0.6
	if enemy_type == "strawman":
		return 0.0
	return float(stats.get("received_knockback_speed", ENEMY_HIT_KNOCKBACK_SPEED))


func _get_player_knockback_speed() -> float:
	return float(stats.get("player_knockback_speed", 110.0))


func _get_player_contact_distance() -> float:
	return _get_collision_radius() + _get_player_collision_radius() + 2.0


func _get_collision_radius() -> float:
	var collision: CircleShape2D = $CollisionShape2D.shape as CircleShape2D
	if collision == null:
		return 10.0
	return collision.radius


func _get_player_collision_radius() -> float:
	if player == null or not is_instance_valid(player):
		return 9.0

	var shape_node := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return 9.0

	var collision: CircleShape2D = shape_node.shape as CircleShape2D
	if collision == null:
		return 9.0
	return collision.radius


func _queue_redraw_if_moved(previous_position: Vector2) -> void:
	if global_position.distance_squared_to(previous_position) > 0.001:
		queue_redraw()


func _get_sort_anchor_position() -> Vector2:
	return global_position


func _draw_character_shadow(base: Vector2) -> void:
	if CharacterVisuals.has_visual(enemy_type):
		draw_rect(CharacterVisuals.get_shadow_rect(enemy_type, base), Color(0, 0, 0, 0.18))
		return

	var size: Vector2 = stats["size"]
	draw_rect(Rect2(base + Vector2(-size.x * 0.45, size.y * 0.35), Vector2(size.x * 0.9, 8)), Color(0, 0, 0, 0.18))


func _draw_character_visual(base: Vector2) -> void:
	var texture_data: Dictionary = CharacterVisuals.get_state_texture_draw_data(enemy_type, CharacterVisuals.cardinal_to_visual_direction(facing_direction), _get_visual_state(), base)
	var texture: Texture2D = texture_data.get("texture", null)
	if texture == null:
		return

	var modulate: Color = Color.WHITE
	if hit_flash_timer > 0.0:
		modulate = Color(1.0, 0.78, 0.78, 1.0)

	draw_texture_rect_region(texture, texture_data.get("draw_rect", Rect2()), texture_data.get("source_rect", Rect2(Vector2.ZERO, texture.get_size())), modulate, false, true)


func _get_visual_state() -> String:
	if attack_windup_timer > 0.0 or slam_charge > 0.0:
		return "attack"
	return "idle"
