extends Node2D

const LevelData := preload("res://data/levels/level_data.gd")
const LevelScene := preload("res://scenes/levels/Level.tscn")
const GameCamera := preload("res://scripts/core/game_camera.gd")
const LevelMusicTheme := preload("res://scripts/audio/level_music_theme.gd")
const CombatDebug := preload("res://scripts/core/combat_debug.gd")

@export var level_music_themes: Array[LevelMusicTheme] = []

var levels: Array[Dictionary] = []
var current_level_index: int = 0
var current_level: Node = null
var run_state: String = "playing"
var combat_music_active: bool = false
var selected_difficulty_id: String = "normal"
var difficulty_multiplier: float = 1.0
var difficulty_selected: bool = false

@onready var level_container: Node2D = $LevelContainer
@onready var entity_layer: Node2D = $EntityLayer
@onready var player: CharacterBody2D = $EntityLayer/Player
@onready var camera_rig: Node2D = $CameraRig
@onready var camera: GameCamera = $CameraRig/Camera2D
@onready var ui: CanvasLayer = $UI
@onready var sound_theme_manager: SoundThemeManager = $SoundThemeManager


func _ready() -> void:
	camera.apply_defaults()
	levels = LevelData.get_levels()
	player.hp_changed.connect(_on_player_hp_changed)
	player.weapon_changed.connect(_on_player_weapon_changed)
	player.died.connect(_on_player_died)
	ui.difficulty_selected.connect(_on_difficulty_selected)
	ui.restart_requested.connect(start_new_run)
	ui.quit_requested.connect(_quit_game)
	ui.show_difficulty_screen()


func _process(_delta: float) -> void:
	if is_instance_valid(player):
		camera_rig.global_position = player.get_visual_position()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_F3 or key_event.physical_keycode == KEY_F3:
			var enabled: bool = CombatDebug.toggle()
			print("combat_debug=%s" % enabled)
			_refresh_combat_debug_draw()
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_F7 or key_event.physical_keycode == KEY_F7:
			var enemy_logic_enabled: bool = CombatDebug.toggle_enemy_logic()
			print("enemy_logic=%s" % enemy_logic_enabled)
			_refresh_combat_debug_draw()
			get_viewport().set_input_as_handled()


func start_new_run() -> void:
	if not difficulty_selected:
		ui.show_difficulty_screen()
		return
	run_state = "playing"
	player.reset_for_new_run()
	player.set_control_enabled(true)
	ui.hide_overlays()
	current_level_index = 0
	set_combat_music_active(false)
	_load_level(current_level_index)
	_on_player_hp_changed(player.hp, player.max_hp)
	_on_player_weapon_changed(player.get_current_weapon())


func get_difficulty_multiplier() -> float:
	return difficulty_multiplier


func get_difficulty_id() -> String:
	return selected_difficulty_id


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
		var heal_amount: int = reward.get("heal_amount", 0)
		if not unlocked:
			heal_amount += 2
		var healed_amount: int = 0
		if heal_amount > 0:
			healed_amount = player.heal(heal_amount)
		if unlocked:
			var message: String = "Gefunden: %s" % reward.get("label", "Waffe")
			if healed_amount > 0:
				message += " und +%d HP" % healed_amount
			ui.show_pickup_message(message)
		elif healed_amount > 0:
			ui.show_pickup_message("Bekannte Waffe. +%d HP" % healed_amount)
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
	set_combat_music_active(false)
	ui.show_victory_screen()


func _load_level(level_index: int) -> void:
	_clear_world_entities()
	if current_level != null:
		current_level.queue_free()

	set_combat_music_active(false)
	_apply_level_music_for(levels[level_index].get("id", ""))

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


func set_level_music(level_theme: AudioStream, action_theme: AudioStream) -> void:
	if sound_theme_manager == null:
		return
	sound_theme_manager.set_level_themes(level_theme, action_theme)
	if combat_music_active:
		sound_theme_manager.enter_action_state()
	else:
		sound_theme_manager.exit_action_state()


func set_combat_music_active(active: bool) -> void:
	combat_music_active = active
	if sound_theme_manager == null:
		return
	if combat_music_active:
		sound_theme_manager.enter_action_state()
	else:
		sound_theme_manager.exit_action_state()


func _apply_level_music_for(level_id: String) -> void:
	var level_theme: AudioStream = null
	var action_theme: AudioStream = null
	var music_theme: LevelMusicTheme = _find_level_music_theme(level_id)
	if music_theme != null and music_theme.enabled:
		level_theme = music_theme.level_theme
		action_theme = music_theme.action_theme
	set_level_music(level_theme, action_theme)


func _find_level_music_theme(level_id: String) -> LevelMusicTheme:
	for music_theme in level_music_themes:
		if music_theme == null:
			continue
		if String(music_theme.level_id) == level_id:
			return music_theme
	return null


func _on_player_hp_changed(current_hp: int, max_hp: int) -> void:
	ui.set_hp(current_hp, max_hp)


func _on_player_weapon_changed(weapon_data: Dictionary) -> void:
	ui.set_weapon(weapon_data.get("name", "Knueppel"))


func _on_player_died() -> void:
	run_state = "dead"
	player.set_control_enabled(false)
	if current_level != null and current_level.has_method("set_active"):
		current_level.set_active(false)
	set_combat_music_active(false)
	ui.show_death_screen()


func _on_difficulty_selected(difficulty_id: String, multiplier: float) -> void:
	selected_difficulty_id = difficulty_id
	difficulty_multiplier = multiplier
	difficulty_selected = true
	start_new_run()


func _quit_game() -> void:
	get_tree().quit()


func _refresh_combat_debug_draw() -> void:
	if is_instance_valid(player) and player.has_method("refresh_combat_debug_draw"):
		player.refresh_combat_debug_draw()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D:
			(enemy as Node2D).queue_redraw()


func get_player() -> CharacterBody2D:
	return player


func get_entity_layer() -> Node2D:
	return entity_layer


func get_current_level() -> Node:
	return current_level


func _clear_world_entities() -> void:
	for child in entity_layer.get_children():
		if child == player:
			continue
		child.queue_free()
