extends Area2D
class_name Pickup

const IsoMapper := preload("res://scripts/core/iso.gd")
const ItemDB := preload("res://data/items/item_db.gd")
const WeaponDB := preload("res://data/weapons/weapon_db.gd")
const ItemVisuals := preload("res://scripts/visual/item_visuals.gd")

var game: Node = null
var reward_data: Dictionary = {}
var item_data = null
var render_origin: Vector2 = Vector2.ZERO
var animation_state: String = "idle"
var pickup_elapsed: float = 0.0
var aura_elapsed: float = 0.0
var intro_elapsed: float = 0.0
var intro_start_position: Vector2 = Vector2.ZERO
var intro_target_position: Vector2 = Vector2.ZERO
var draw_scale: float = 1.0
var draw_alpha: float = 1.0
var draw_lift: float = 0.0

const PICKUP_DURATION := 0.55
const PICKUP_RISE_DISTANCE := 28.0
const PICKUP_SCALE_BONUS := 0.35
const INTRO_DURATION := 0.32
const INTRO_ARC_HEIGHT := 18.0


func setup(game_ref: Node, reward: Dictionary, options: Dictionary = {}) -> void:
	game = game_ref
	reward_data = reward.duplicate(true)
	item_data = ItemDB.get_item_from_reward(reward_data)
	intro_start_position = global_position
	intro_target_position = global_position
	if options.get("spawn_arc", false):
		intro_target_position = intro_start_position + options.get("launch_offset", Vector2(24.0, 8.0))
		animation_state = "intro"
		pickup_elapsed = 0.0
		intro_elapsed = 0.0
		monitoring = false
	queue_redraw()


func set_active(_active: bool) -> void:
	pass


func set_render_origin(new_render_origin: Vector2) -> void:
	render_origin = new_render_origin
	z_index = 1000 + IsoMapper.entity_sort_z_for_foot(global_position) + 1
	queue_redraw()


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	aura_elapsed += delta
	match animation_state:
		"intro":
			_tick_intro_animation(delta)
		"pickup":
			_tick_pickup_animation(delta)
		"idle":
			_try_collect_overlapping_player()
	queue_redraw()


func _draw() -> void:
	var base: Vector2 = IsoMapper.render_offset(position, render_origin)
	base.y -= draw_lift
	var pulse: float = 0.5 + 0.5 * sin(aura_elapsed * 3.6)
	if animation_state == "idle":
		var aura_color: Color = _get_reward_color()
		var glow_color: Color = aura_color.lerp(Color.WHITE, 0.42 + pulse * 0.18)
		var cyan_ring: Color = aura_color.lerp(Color(0.24, 0.94, 1.0, 1.0), 0.52)
		var pink_ring: Color = aura_color.lerp(Color(1.0, 0.38, 0.82, 1.0), 0.46)
		glow_color.a = 0.2 + pulse * 0.18
		cyan_ring.a = 0.22 + pulse * 0.14
		pink_ring.a = 0.18 + (1.0 - pulse) * 0.16
		draw_circle(base + Vector2(0.0, 2.0), 17.0 + pulse * 6.0, glow_color)
		draw_circle(base + Vector2(0.0, 1.0), 11.0 + pulse * 3.0, Color(glow_color.r, glow_color.g, glow_color.b, glow_color.a * 0.8))
		draw_arc(base + Vector2(0.0, 1.0), 20.0 + pulse * 6.0, 0.0, TAU, 48, cyan_ring, 3.0, true)
		draw_arc(base + Vector2(0.0, 1.0), 14.0 + (1.0 - pulse) * 5.0, 0.0, TAU, 40, pink_ring, 2.0, true)
	var texture: Texture2D = item_data.icon if item_data != null and item_data.icon != null else ItemVisuals.get_reward_icon(reward_data)
	if texture != null:
		var shadow_alpha: float = draw_alpha * (0.18 if animation_state != "pickup" else 0.12)
		var texture_size := Vector2(28.0, 28.0) * draw_scale
		var texture_pos := base + Vector2(-texture_size.x * 0.5, -texture_size.y + 10.0)
		draw_rect(Rect2(base + Vector2(-10, 10), Vector2(20, 6)), Color(0, 0, 0, shadow_alpha))
		draw_texture_rect(texture, Rect2(texture_pos, texture_size), false, Color(1, 1, 1, draw_alpha))
		return

	var color: Color = _get_reward_color()
	color.a = draw_alpha
	draw_rect(Rect2(base + Vector2(-8, 8), Vector2(16, 6)), Color(0, 0, 0, 0.2 * draw_alpha))
	if reward_data.get("type", "") == "amulet":
		var points := PackedVector2Array([
			base + Vector2(0, -14) * draw_scale,
			base + Vector2(8, -2) * draw_scale,
			base + Vector2(0, 10) * draw_scale,
			base + Vector2(-8, -2) * draw_scale
		])
		draw_polygon(
			points,
			[color]
		)
		draw_circle(base + Vector2(0, -2) * draw_scale, 3.0 * draw_scale, Color(1, 1, 1, draw_alpha))
	else:
		var size := Vector2(12.0, 20.0) * draw_scale
		draw_rect(Rect2(base + Vector2(-size.x * 0.5, -10.0 * draw_scale), size), color)


func _on_body_entered(body: Node) -> void:
	_try_collect(body)


func _try_collect_overlapping_player() -> void:
	if animation_state != "idle" or not monitoring:
		return
	for body in get_overlapping_bodies():
		if body != null and is_instance_valid(body) and body.is_in_group("player"):
			_try_collect(body)
			return


func _try_collect(body: Node) -> void:
	if animation_state != "idle" or body == null or not is_instance_valid(body) or not body.is_in_group("player") or game == null:
		return

	if reward_data.get("type", "") == "amulet" and game.has_method("spawn_xp_popup"):
		game.spawn_xp_popup(100, global_position)
	var result: Dictionary = game.give_reward(reward_data)
	if not result.get("consumed", false):
		return
	var popup_text: String = result.get("stat_popup_text", "")
	if not popup_text.is_empty() and game.has_method("spawn_text_popup"):
		game.spawn_text_popup(popup_text, global_position, result.get("stat_popup_color", Color.WHITE))
	animation_state = "pickup"
	pickup_elapsed = 0.0
	monitoring = false
	collision_layer = 0
	collision_mask = 0
	queue_redraw()


func _tick_intro_animation(delta: float) -> void:
	intro_elapsed += delta
	var progress: float = clampf(intro_elapsed / INTRO_DURATION, 0.0, 1.0)
	global_position = intro_start_position.lerp(intro_target_position, progress)
	draw_lift = sin(progress * PI) * INTRO_ARC_HEIGHT
	draw_scale = 1.0
	draw_alpha = 1.0
	set_render_origin(render_origin)
	if progress >= 1.0:
		global_position = intro_target_position
		draw_lift = 0.0
		animation_state = "idle"
		monitoring = true


func _tick_pickup_animation(delta: float) -> void:
	pickup_elapsed += delta
	var progress: float = clampf(pickup_elapsed / PICKUP_DURATION, 0.0, 1.0)
	draw_lift = progress * PICKUP_RISE_DISTANCE
	draw_scale = 1.0 + progress * PICKUP_SCALE_BONUS
	draw_alpha = 1.0 - progress
	if progress >= 1.0:
		queue_free()


func _get_reward_color() -> Color:
	var color: Color = Color8(240, 210, 104)
	if item_data != null and reward_data.get("type", "") == "weapon":
		color = item_data.color
	elif reward_data.get("type", "") == "weapon":
		var weapon_id: String = reward_data.get("id", WeaponDB.get_default_weapon_id())
		color = WeaponDB.get_weapon(weapon_id).color
	elif reward_data.get("type", "") == "heal":
		color = Color8(204, 82, 82)
	elif reward_data.get("type", "") == "amulet":
		color = Color8(110, 218, 255)
	return color
