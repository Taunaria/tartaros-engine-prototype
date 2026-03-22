extends Area2D

const IsoMapper := preload("res://scripts/core/iso.gd")

var reward_data: Dictionary = {}
var game: Node = null
var opened: bool = false
var player_in_range: bool = false
var render_origin: Vector2 = Vector2.ZERO
var fade_elapsed: float = 0.0
var fade_started: bool = false

const FADE_DELAY := 0.3
const FADE_DURATION := 0.6


func setup(game_ref: Node, reward: Dictionary) -> void:
	game = game_ref
	reward_data = reward.duplicate(true)
	queue_redraw()


func set_active(_active: bool) -> void:
	pass


func set_render_origin(new_render_origin: Vector2) -> void:
	render_origin = new_render_origin
	z_index = 1000 + IsoMapper.entity_sort_z_for_foot(global_position) + 1
	queue_redraw()


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if fade_started:
		fade_elapsed += _delta
		var alpha: float = 1.0
		if fade_elapsed > FADE_DELAY:
			alpha = 1.0 - clampf((fade_elapsed - FADE_DELAY) / FADE_DURATION, 0.0, 1.0)
		modulate.a = alpha
		if fade_elapsed >= FADE_DELAY + FADE_DURATION:
			queue_free()
		return

	if opened or not player_in_range:
		return

	if Input.is_action_just_pressed("interact") and game != null:
		opened = true
		if game.has_method("play_sfx"):
			game.play_sfx("chest_open")
		if game.has_method("spawn_xp_popup"):
			game.spawn_xp_popup(25, global_position)
		game.give_reward(reward_data)
		game.show_interaction_hint("")
		fade_started = true
		fade_elapsed = 0.0
		monitoring = false
		collision_layer = 0
		collision_mask = 0
		queue_redraw()


func _draw() -> void:
	var base: Vector2 = IsoMapper.render_offset(position, render_origin)
	var base_color: Color = Color8(123, 80, 41)
	var lid_color: Color = Color8(175, 126, 65)
	if opened:
		base_color = Color8(92, 92, 92)
		lid_color = Color8(152, 152, 152)

	draw_rect(Rect2(base + Vector2(-12, 8), Vector2(24, 8)), Color(0, 0, 0, 0.18))
	draw_rect(Rect2(base + Vector2(-12, -4), Vector2(24, 14)), base_color)
	draw_rect(Rect2(base + Vector2(-14, -12), Vector2(28, 10)), lid_color)


func _on_body_entered(body: Node) -> void:
	if opened or not body.is_in_group("player"):
		return

	player_in_range = true
	if game != null:
		game.show_interaction_hint("E: Kiste oeffnen")


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	player_in_range = false
	if game != null:
		game.show_interaction_hint("")
