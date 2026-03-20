extends Node2D

const LevelData := preload("res://data/levels/level_data.gd")
const LevelScene := preload("res://scenes/levels/Level.tscn")
const GameCamera := preload("res://scripts/core/game_camera.gd")

var levels: Array[Dictionary] = []
var current_level_index: int = 0
var current_level: Node = null
var run_state: String = "playing"

@onready var level_container: Node2D = $LevelContainer
@onready var player: CharacterBody2D = $Player
@onready var camera_rig: Node2D = $CameraRig
@onready var camera: GameCamera = $CameraRig/Camera2D
@onready var ui: CanvasLayer = $UI


func _ready() -> void:
	camera.apply_defaults()
	levels = LevelData.get_levels()
	player.hp_changed.connect(_on_player_hp_changed)
	player.weapon_changed.connect(_on_player_weapon_changed)
	player.died.connect(_on_player_died)
	ui.restart_requested.connect(start_new_run)
	ui.quit_requested.connect(_quit_game)
	start_new_run()


func _process(_delta: float) -> void:
	if is_instance_valid(player):
		camera_rig.global_position = player.get_visual_position()


func start_new_run() -> void:
	run_state = "playing"
	player.reset_for_new_run()
	player.set_control_enabled(true)
	ui.hide_overlays()
	current_level_index = 0
	_load_level(current_level_index)
	_on_player_hp_changed(player.hp, player.max_hp)
	_on_player_weapon_changed(player.get_current_weapon())


func advance_to_level(level_index: int) -> void:
	if run_state != "playing":
		return

	if level_index < 0 or level_index >= levels.size():
		complete_demo()
		return

	current_level_index = level_index
	_load_level(current_level_index)


func give_reward(reward: Dictionary) -> void:
	if reward.is_empty():
		return

	var reward_type: String = reward.get("type", "")
	if reward_type == "weapon":
		var weapon_id: String = reward.get("id", "")
		var unlocked: bool = player.unlock_weapon(weapon_id)
		player.equip_weapon(weapon_id)
		if unlocked:
			ui.show_pickup_message("Gefunden: %s" % reward.get("label", "Waffe"))
		else:
			var healed: int = player.heal(2)
			if healed > 0:
				ui.show_pickup_message("Bekannte Waffe. +%d HP" % healed)
	elif reward_type == "heal":
		var healed_amount: int = player.heal(reward.get("amount", 0))
		ui.show_pickup_message("+%d HP" % healed_amount)


func show_interaction_hint(text: String) -> void:
	ui.show_interaction_hint(text)


func complete_demo() -> void:
	run_state = "victory"
	player.set_control_enabled(false)
	if current_level != null and current_level.has_method("set_active"):
		current_level.set_active(false)
	ui.show_victory_screen()


func _load_level(level_index: int) -> void:
	if current_level != null:
		current_level.queue_free()

	current_level = LevelScene.instantiate()
	level_container.add_child(current_level)
	current_level.setup(self, levels[level_index], level_index, levels.size())
	player.global_position = current_level.get_start_world_position()
	player.set_render_origin(current_level.get_render_origin())
	if current_level.has_method("set_active"):
		current_level.set_active(true)
	player.set_control_enabled(true)
	ui.show_level_title_text(levels[level_index].get("name", ""))
	show_interaction_hint("")


func _on_player_hp_changed(current_hp: int, max_hp: int) -> void:
	ui.set_hp(current_hp, max_hp)


func _on_player_weapon_changed(weapon_data: Dictionary) -> void:
	ui.set_weapon(weapon_data.get("name", "Knueppel"))


func _on_player_died() -> void:
	run_state = "dead"
	player.set_control_enabled(false)
	if current_level != null and current_level.has_method("set_active"):
		current_level.set_active(false)
	ui.show_death_screen()


func _quit_game() -> void:
	get_tree().quit()
