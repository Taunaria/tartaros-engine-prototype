extends CharacterBody2D

signal defeated(enemy: Node, drop_data: Dictionary)
signal engagement_changed(enemy: Node, engaged: bool)

const IsoMapper := preload("res://scripts/core/iso.gd")
const CombatDebug := preload("res://scripts/core/combat_debug.gd")

const STATS := {
	"zombie": {
		"display_name": "Zombie",
		"speed": 62.0,
		"max_hp": 5,
		"damage": 1,
		"chase_range": 240.0,
		"melee_range": 24.0,
		"attack_cooldown": 0.95,
		"body_color": Color8(97, 141, 92),
		"head_color": Color8(141, 168, 100),
		"size": Vector2(20, 20)
	},
	"skeleton": {
		"display_name": "Skelett",
		"speed": 84.0,
		"max_hp": 6,
		"damage": 2,
		"chase_range": 270.0,
		"melee_range": 28.0,
		"attack_cooldown": 0.7,
		"body_color": Color8(203, 203, 186),
		"head_color": Color8(241, 231, 203),
		"size": Vector2(18, 22)
	},
	"strawman": {
		"display_name": "Strohpupe",
		"speed": 0.0,
		"max_hp": 20,
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
var hit_flash_timer: float = 0.0
var slam_timer: float = 0.0
var slam_charge: float = 0.0
var render_origin: Vector2 = Vector2.ZERO
var _engaged: bool = false


func setup(type_name: String, game_ref: Node, extra_data: Dictionary = {}) -> void:
	enemy_type = type_name
	stats = STATS.get(enemy_type, STATS["zombie"]).duplicate(true)
	game = game_ref
	player = game.get_node("Player")
	hp = stats["max_hp"]
	drop_data = extra_data.get("drop", {})
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


func set_render_origin(new_render_origin: Vector2) -> void:
	render_origin = new_render_origin
	z_index = 1000 + IsoMapper.sort_key_for_logic(global_position)
	queue_redraw()


func _physics_process(delta: float) -> void:
	var previous_position: Vector2 = global_position

	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		queue_redraw()

	if not CombatDebug.enemy_logic_enabled:
		_set_engaged(false)
		velocity = Vector2.ZERO
		move_and_slide()
		_queue_redraw_if_moved(previous_position)
		return

	if attack_timer > 0.0:
		attack_timer -= delta

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
		move_and_slide()
		_queue_redraw_if_moved(previous_position)
		return

	var to_player: Vector2 = player.global_position - global_position
	var distance: float = to_player.length()
	if distance > stats["chase_range"]:
		_set_engaged(false)
		velocity = Vector2.ZERO
		move_and_slide()
		_queue_redraw_if_moved(previous_position)
		return

	_set_engaged(true)

	var stop_distance: float = maxf(float(stats["melee_range"]), _get_player_contact_distance())

	if enemy_type == "boss" and slam_timer <= 0.0 and slam_charge <= 0.0 and distance < 150.0:
		slam_charge = stats["slam_windup"]
		slam_timer = stats["slam_cooldown"]
		velocity = Vector2.ZERO
		move_and_slide()
		_queue_redraw_if_moved(previous_position)
		return

	if distance > stop_distance:
		velocity = to_player.normalized() * stats["speed"]
	else:
		velocity = Vector2.ZERO
		if distance <= float(stats["melee_range"]) and attack_timer <= 0.0:
			attack_timer = stats["attack_cooldown"]
			player.take_damage(stats["damage"])
	move_and_slide()
	z_index = 1000 + IsoMapper.sort_key_for_logic(global_position)
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
	var body_color: Color = stats["body_color"]
	var head_color: Color = stats["head_color"]
	if hit_flash_timer > 0.0:
		body_color = Color8(255, 128, 128)
		head_color = Color8(255, 206, 206)

	var size: Vector2 = stats["size"]
	var width: float = size.x
	var height: float = size.y
	_draw_hp_bar(base, width, height)
	draw_rect(Rect2(base + Vector2(-width * 0.45, height * 0.35), Vector2(width * 0.9, 8)), Color(0, 0, 0, 0.18))
	draw_rect(Rect2(base + Vector2(-width * 0.45, -height * 0.1), Vector2(width * 0.9, height * 0.55)), body_color)
	draw_rect(Rect2(base + Vector2(-width * 0.3, -height * 0.45), Vector2(width * 0.6, height * 0.35)), head_color)

	if enemy_type == "boss" and slam_charge > 0.0:
		var radius: float = float(stats["slam_radius"]) * (1.0 - slam_charge / float(stats["slam_windup"]))
		draw_arc(base, max(radius, 12.0), 0.0, TAU, 48, Color8(255, 128, 80), 4.0)

	if CombatDebug.enabled:
		_draw_debug_hurtbox()


func take_damage(amount: int) -> void:
	hp = max(hp - amount, 0)
	hit_flash_timer = 0.16
	queue_redraw()
	if hp <= 0:
		emit_signal("defeated", self, drop_data)
		queue_free()


func _resolve_slam() -> void:
	if player == null or not is_instance_valid(player):
		return

	if global_position.distance_to(player.global_position) <= stats["slam_radius"]:
		player.take_damage(stats["slam_damage"])


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
	var size: Vector2 = stats["size"]
	return PackedVector2Array([
		base + Vector2(0.0, -size.y * 0.05),
		base + Vector2(0.0, -size.y * 0.35),
		base + Vector2(0.0, -size.y * 0.65)
	])


func get_attack_target_position() -> Vector2:
	if active and CombatDebug.enemy_logic_enabled and velocity.length_squared() > 0.0:
		return global_position + velocity * get_physics_process_delta_time()
	return global_position


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
