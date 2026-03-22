extends Area2D

const IsoMapper := preload("res://scripts/core/iso.gd")
const ChestClosedTexture := preload("res://output/imagegen/props/chest_closed.png")
const ChestOpenTexture := preload("res://output/imagegen/props/chest_open.png")

var reward_data: Dictionary = {}
var game: Node = null
var opened: bool = false
var player_in_range: bool = false
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
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
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
		monitoring = false
		collision_layer = 0
		collision_mask = 0
		queue_redraw()


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
