extends TextureRect

const ItemVisuals := preload("res://scripts/visual/item_visuals.gd")

@export var pulse_speed := 4.0
@export var pulse_amplitude := 0.05

var pulse_time := 0.0
var current_scale := 1.0
var current_tint := Color8(235, 242, 255)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_as_relative = false
	z_index = 4000
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	custom_minimum_size = Vector2(112.0, 112.0)
	size = custom_minimum_size
	pivot_offset = size * 0.5
	texture = ItemVisuals.get_crosshair_texture()
	visible = true


func _process(delta: float) -> void:
	pulse_time += delta
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	global_position = mouse_position - (size * 0.5)
	_update_feedback()


func _update_feedback() -> void:
	var pulse_scale: float = 1.0 + sin(pulse_time * pulse_speed) * pulse_amplitude
	var charge_ratio: float = 0.0
	var attack_ratio: float = 0.0
	var hover_ratio: float = _get_hover_enemy_ratio()
	var player: Node = _get_player()
	if player != null:
		if player.has_method("get_attack_charge_ratio"):
			charge_ratio = player.get_attack_charge_ratio()
		if player.has_method("get_attack_feedback_ratio"):
			attack_ratio = player.get_attack_feedback_ratio()
	current_scale = pulse_scale + charge_ratio * 0.08 + attack_ratio * 0.12 + hover_ratio * 0.04
	scale = Vector2.ONE * current_scale
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
	var mouse_position: Vector2 = global_position + (size * 0.5)
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
