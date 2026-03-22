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
var fade_elapsed: float = 0.0
var fade_started: bool = false

const FADE_DELAY := 0.2
const FADE_DURATION := 0.6


func setup(game_ref: Node, reward: Dictionary) -> void:
	game = game_ref
	reward_data = reward.duplicate(true)
	item_data = ItemDB.get_item_from_reward(reward_data)
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
	if not fade_started:
		return

	fade_elapsed += delta
	var alpha: float = 1.0
	if fade_elapsed > FADE_DELAY:
		alpha = 1.0 - clampf((fade_elapsed - FADE_DELAY) / FADE_DURATION, 0.0, 1.0)
	modulate.a = alpha
	if fade_elapsed >= FADE_DELAY + FADE_DURATION:
		queue_free()


func _draw() -> void:
	var base: Vector2 = IsoMapper.render_offset(position, render_origin)
	var texture: Texture2D = item_data.icon if item_data != null and item_data.icon != null else ItemVisuals.get_reward_icon(reward_data)
	if texture != null:
		draw_rect(Rect2(base + Vector2(-10, 10), Vector2(20, 6)), Color(0, 0, 0, 0.18))
		draw_texture_rect(texture, Rect2(base + Vector2(-14, -18), Vector2(28, 28)), false)
		return

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

	draw_rect(Rect2(base + Vector2(-8, 8), Vector2(16, 6)), Color(0, 0, 0, 0.2))
	if reward_data.get("type", "") == "amulet":
		draw_polygon(
			PackedVector2Array([
				base + Vector2(0, -14),
				base + Vector2(8, -2),
				base + Vector2(0, 10),
				base + Vector2(-8, -2)
			]),
			[color]
		)
		draw_circle(base + Vector2(0, -2), 3.0, Color.WHITE)
	else:
		draw_rect(Rect2(base + Vector2(-6, -10), Vector2(12, 20)), color)


func _on_body_entered(body: Node) -> void:
	if fade_started or not body.is_in_group("player") or game == null:
		return

	if reward_data.get("type", "") == "amulet" and game.has_method("spawn_xp_popup"):
		game.spawn_xp_popup(100, global_position)
	game.give_reward(reward_data)
	fade_started = true
	fade_elapsed = 0.0
	monitoring = false
	collision_layer = 0
	collision_mask = 0
	queue_redraw()
