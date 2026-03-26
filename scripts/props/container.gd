extends Area2D
class_name LootContainer

const IsoMapper := preload("res://scripts/core/iso.gd")

var contents: Array = []
var game: Node = null
var level: Node = null
var opened: bool = false
var render_origin: Vector2 = Vector2.ZERO


func setup(game_ref: Node, level_ref: Node, contents_data: Variant) -> void:
	game = game_ref
	level = level_ref
	contents = _normalize_contents(contents_data)
	queue_redraw()


func set_active(_active: bool) -> void:
	pass


func set_render_origin(new_render_origin: Vector2) -> void:
	render_origin = new_render_origin
	z_index = 1000 + IsoMapper.entity_sort_z_for_foot(global_position) + 1
	queue_redraw()


func _ready() -> void:
	add_to_group("player_attack_openables")


func open_container() -> bool:
	if opened:
		return false

	opened = true
	remove_from_group("player_attack_openables")
	monitoring = false
	collision_layer = 0
	collision_mask = 0
	if game != null and game.has_method("play_sfx"):
		game.play_sfx("chest_open")
	var xp_reward: int = _get_open_xp_reward()
	if xp_reward > 0 and game != null and game.has_method("spawn_xp_popup"):
		game.spawn_xp_popup(xp_reward, global_position)
	_spawn_contents()
	queue_redraw()
	return true


func open_chest() -> bool:
	return open_container()


func _spawn_contents() -> void:
	if contents.is_empty():
		return

	if level != null and level.has_method("spawn_pickup_at_world"):
		var launch_offsets: Array = _build_launch_offsets(contents.size())
		for index in range(contents.size()):
			level.spawn_pickup_at_world(global_position, contents[index], {
				"spawn_arc": true,
				"launch_offset": launch_offsets[index]
			})
		return

	if game != null and game.has_method("give_reward"):
		for reward in contents:
			game.give_reward(reward)


func _build_launch_offsets(count: int) -> Array:
	var offsets: Array = []
	var player_position: Vector2 = global_position
	if game != null and game.has_method("get_player"):
		var player: Node = game.get_player()
		if player != null and is_instance_valid(player):
			player_position = player.global_position
	var away_from_player := (global_position - player_position).normalized()
	if away_from_player.length_squared() <= 0.001:
		away_from_player = Vector2.RIGHT
	var base_angle: float = away_from_player.angle()
	for index in range(count):
		var spread_ratio: float = 0.0 if count <= 1 else (float(index) / float(count - 1)) - 0.5
		var angle: float = base_angle + spread_ratio * 1.15 + randf_range(-0.28, 0.28)
		var direction := Vector2.RIGHT.rotated(angle)
		var offset := direction * randf_range(22.0, 34.0)
		offset.y = absf(offset.y) * 0.42 + randf_range(4.0, 10.0)
		offsets.append(offset)
	return offsets


func _normalize_contents(contents_data: Variant) -> Array:
	var normalized: Array = []
	if contents_data is Dictionary:
		var reward: Dictionary = (contents_data as Dictionary).duplicate(true)
		if not reward.is_empty():
			normalized.append(reward)
	elif contents_data is Array:
		for entry in contents_data:
			if entry is Dictionary and not (entry as Dictionary).is_empty():
				normalized.append((entry as Dictionary).duplicate(true))
	return normalized


func _get_open_xp_reward() -> int:
	return 25
