extends Area2D

const IsoMapper := preload("res://scripts/core/iso.gd")
const WeaponDB := preload("res://data/weapons/weapon_db.gd")

var game: Node = null
var reward_data: Dictionary = {}
var render_origin: Vector2 = Vector2.ZERO


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


func _draw() -> void:
	var base: Vector2 = IsoMapper.render_offset(position, render_origin)
	var color: Color = Color8(240, 210, 104)
	if reward_data.get("type", "") == "weapon":
		var weapon_id: String = reward_data.get("id", WeaponDB.get_default_weapon_id())
		color = WeaponDB.get_weapon(weapon_id).get("color", color)
	elif reward_data.get("type", "") == "heal":
		color = Color8(204, 82, 82)

	draw_rect(Rect2(base + Vector2(-8, 8), Vector2(16, 6)), Color(0, 0, 0, 0.2))
	draw_rect(Rect2(base + Vector2(-6, -10), Vector2(12, 20)), color)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player") or game == null:
		return

	game.give_reward(reward_data)
	queue_free()
