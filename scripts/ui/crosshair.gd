extends Sprite2D

const ItemVisuals := preload("res://scripts/visual/item_visuals.gd")

@export var target_display_size := 112.0
@export var pulse_speed := 4.0
@export var pulse_amplitude := 0.05

var pulse_time := 0.0
var base_scale := 1.0
var hover_scale_bonus := 0.0
var attack_scale_bonus := 0.0
var charge_scale_bonus := 0.0
var current_tint := Color.WHITE


func _ready() -> void:
	top_level = true
	z_as_relative = false
	z_index = 4000
	centered = true
	texture = ItemVisuals.get_crosshair_texture()
	if texture == null:
		texture = _make_fallback_texture()
	base_scale = target_display_size / maxf(1.0, float(texture.get_width()))
	scale = Vector2.ONE * base_scale
	modulate = Color.WHITE
	visible = true


func _process(delta: float) -> void:
	pulse_time += delta
	global_position = get_global_mouse_position()
	_update_feedback()


func _update_feedback() -> void:
	var pulse_scale: float = 1.0 + sin(pulse_time * pulse_speed) * pulse_amplitude
	var player: Node = _get_player()
	var charge_ratio: float = 0.0
	var attack_ratio: float = 0.0
	if player != null:
		if player.has_method("get_attack_charge_ratio"):
			charge_ratio = player.get_attack_charge_ratio()
		if player.has_method("get_attack_feedback_ratio"):
			attack_ratio = player.get_attack_feedback_ratio()
	var hover_ratio: float = _get_hover_enemy_ratio()
	charge_scale_bonus = charge_ratio * 0.08
	attack_scale_bonus = attack_ratio * 0.12
	hover_scale_bonus = hover_ratio * 0.04
	var total_scale: float = pulse_scale + charge_scale_bonus + attack_scale_bonus + hover_scale_bonus
	scale = Vector2.ONE * (base_scale * total_scale)

	current_tint = Color8(235, 242, 255)
	if hover_ratio > 0.0:
		current_tint = current_tint.lerp(Color8(255, 208, 124), minf(hover_ratio * 0.75, 0.75))
	if attack_ratio > 0.0:
		current_tint = current_tint.lerp(Color.WHITE, minf(attack_ratio * 0.8, 0.8))
	modulate = current_tint


func _get_player() -> Node:
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0]


func _get_hover_enemy_ratio() -> float:
	var mouse_position: Vector2 = global_position
	var nearest_distance: float = INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not enemy.has_method("get_visual_position"):
			continue
		var enemy_screen_position: Vector2 = enemy.get_visual_position()
		nearest_distance = minf(nearest_distance, enemy_screen_position.distance_to(mouse_position))
	if nearest_distance == INF:
		return 0.0
	return clampf(1.0 - nearest_distance / 72.0, 0.0, 1.0)


func _make_fallback_texture() -> Texture2D:
	var image := Image.create(112, 112, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(image)
