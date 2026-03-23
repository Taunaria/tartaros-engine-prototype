extends Area2D

const IsoMapper := preload("res://scripts/core/iso.gd")
const ChestClosedTexture := preload("res://output/imagegen/props/chest_closed.png")
const ChestOpenTexture := preload("res://output/imagegen/props/chest_open.png")

var reward_data: Dictionary = {}
var game: Node = null
var level: Node = null
var opened: bool = false
var render_origin: Vector2 = Vector2.ZERO


func setup(game_ref: Node, level_ref: Node, reward: Dictionary) -> void:
	game = game_ref
	level = level_ref
	reward_data = reward.duplicate(true)
	queue_redraw()


func set_active(_active: bool) -> void:
	pass


func set_render_origin(new_render_origin: Vector2) -> void:
	render_origin = new_render_origin
	z_index = 1000 + IsoMapper.entity_sort_z_for_foot(global_position) + 1
	queue_redraw()


func _ready() -> void:
	add_to_group("player_attack_openables")


func open_chest() -> bool:
	if opened:
		return false

	opened = true
	remove_from_group("player_attack_openables")
	monitoring = false
	collision_layer = 0
	collision_mask = 0
	if game != null and game.has_method("play_sfx"):
		game.play_sfx("chest_open")
	if game != null and game.has_method("spawn_xp_popup"):
		game.spawn_xp_popup(25, global_position)
	if not reward_data.is_empty():
		if level != null and level.has_method("spawn_pickup_at_world"):
			level.spawn_pickup_at_world(global_position, reward_data)
		elif game != null and game.has_method("give_reward"):
			game.give_reward(reward_data)
	queue_redraw()
	return true


func _draw() -> void:
	var base: Vector2 = IsoMapper.render_offset(position, render_origin)
	var texture: Texture2D = ChestOpenTexture if opened else ChestClosedTexture
	if texture == null:
		return

	var texture_size: Vector2 = texture.get_size()
	var target_height: float = 72.0
	var scale: float = target_height / maxf(texture_size.y, 1.0)
	var draw_size: Vector2 = texture_size * scale
	var chest_rect := Rect2(base + Vector2(-draw_size.x * 0.5, -draw_size.y + 18.0), draw_size)
	draw_rect(Rect2(chest_rect.position + Vector2(6, 10), Vector2(chest_rect.size.x - 12.0, 10.0)), Color(0, 0, 0, 0.18))
	draw_texture_rect(texture, chest_rect, false)
