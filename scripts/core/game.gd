extends Node2D

const LevelData := preload("res://data/levels/level_data.gd")
const ItemDB := preload("res://data/items/item_db.gd")
const LevelScene := preload("res://scenes/levels/Level.tscn")
const GameCamera := preload("res://scripts/core/game_camera.gd")
const LevelMusicTheme := preload("res://scripts/audio/level_music_theme.gd")
const CombatDebug := preload("res://scripts/core/combat_debug.gd")
const SfxManager := preload("res://scripts/audio/sfx_manager.gd")
const XpPopupScene := preload("res://scenes/ui/XpPopup.tscn")

@export var level_music_themes: Array[LevelMusicTheme] = []

var levels: Array[Dictionary] = []
var current_level_index: int = 0
var current_level: Node = null
var run_state: String = "playing"
var combat_music_active: bool = false
var selected_difficulty_id: String = "normal"
var difficulty_multiplier: float = 1.0
var difficulty_selected: bool = false
var current_level_amulet_collected: bool = false

@onready var level_container: Node2D = $LevelContainer
@onready var entity_layer: Node2D = $EntityLayer
@onready var player: CharacterBody2D = $EntityLayer/Player
@onready var camera_rig: Node2D = $CameraRig
@onready var camera: GameCamera = $CameraRig/Camera2D
@onready var ui: CanvasLayer = $UI
@onready var sound_theme_manager: SoundThemeManager = $SoundThemeManager
@onready var sfx_manager: SfxManager = $SfxManager
@onready var feedback_layer: Node2D = $FeedbackLayer


func _ready() -> void:
	camera.apply_defaults()
	levels = LevelData.get_levels()
	player.hp_changed.connect(_on_player_hp_changed)
	player.weapon_changed.connect(_on_player_weapon_changed)
	player.died.connect(_on_player_died)
	if player.has_method("set_game_ref"):
		player.set_game_ref(self)
	ui.difficulty_selected.connect(_on_difficulty_selected)
	ui.restart_requested.connect(start_new_run)
	ui.quit_requested.connect(_quit_game)
	ui.show_difficulty_screen()


func _process(_delta: float) -> void:
	if is_instance_valid(player):
		camera_rig.global_position = player.get_visual_position()


func _unhandled_input(event: InputEvent) -> void:
	CombatDebug.register_last_input(event)

	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_F3 or key_event.physical_keycode == KEY_F3:
			var enabled: bool = CombatDebug.toggle()
			print("combat_debug=%s" % enabled)
			_refresh_combat_debug_draw()
			_refresh_direction_debug_draw()
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_F7 or key_event.physical_keycode == KEY_F7:
			var enemy_logic_enabled: bool = CombatDebug.toggle_enemy_logic()
			print("enemy_logic=%s" % enemy_logic_enabled)
			_refresh_combat_debug_draw()
			_refresh_direction_debug_draw()
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_F10 or key_event.physical_keycode == KEY_F10:
			var direction_overlay_enabled: bool = CombatDebug.toggle_direction_overlay()
			print("direction_overlay=%s" % direction_overlay_enabled)
			_refresh_direction_debug_draw()
			if ui != null and is_instance_valid(ui) and ui.has_method("refresh_direction_debug_overlay"):
				ui.refresh_direction_debug_overlay()
			get_viewport().set_input_as_handled()


func start_new_run() -> void:
	if not difficulty_selected:
		ui.show_difficulty_screen()
		return
	run_state = "playing"
	current_level_amulet_collected = false
	player.reset_for_new_run()
	player.set_control_enabled(true)
	ui.hide_overlays()
	current_level_index = 0
	set_combat_music_active(false)
	_load_level(current_level_index)
	_on_player_hp_changed(player.hp, player.max_hp)
	_on_player_weapon_changed(player.get_current_weapon())
	ui.set_amulet_collected(false)


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

	var item_data = ItemDB.get_item_from_reward(reward)
	var reward_type: String = reward.get("type", "")
	if reward_type == "weapon" and item_data != null:
		var weapon_data = item_data
		var unlocked: bool = player.unlock_weapon(weapon_data.id)
		player.equip_weapon(weapon_data.id)
		var heal_amount: int = reward.get("heal_amount", 0)
		if not unlocked:
			heal_amount += 2
		var healed_amount: int = 0
		if heal_amount > 0:
			healed_amount = player.heal(heal_amount)
		if unlocked:
			var message: String = "Gefunden: %s" % weapon_data.display_name
			if healed_amount > 0:
				message += " und +%d HP" % healed_amount
			ui.show_pickup_message(message)
		elif healed_amount > 0:
			ui.show_pickup_message("Bekannte Waffe. +%d HP" % healed_amount)
		play_sfx("pickup")
	elif reward_type == "heal":
		var healed_amount: int = player.heal(reward.get("amount", 0))
		ui.show_pickup_message("+%d HP" % healed_amount)
		play_sfx("pickup")
	elif reward_type == "amulet" and item_data != null:
		player.obtain_amulet()
		current_level_amulet_collected = true
		ui.show_pickup_message(item_data.display_name if not item_data.display_name.is_empty() else reward.get("label", "Amulett erhalten"))
		ui.set_amulet_collected(true)
		play_sfx("pickup")
		if current_level != null and current_level.has_method("refresh_exit_state"):
			current_level.refresh_exit_state()


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

	current_level_amulet_collected = false
	set_combat_music_active(false)
	_apply_level_music_for(levels[level_index].get("id", ""))

	current_level = LevelScene.instantiate()
	level_container.add_child(current_level)
	current_level.setup(self, levels[level_index], level_index, levels.size())
	player.global_position = current_level.get_start_world_position()
	player.set_render_origin(current_level.get_render_origin())
	player.clear_amulet()
	if current_level.has_method("set_active"):
		current_level.set_active(true)
	player.set_control_enabled(true)
	ui.set_amulet_collected(false)
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


func play_sfx(name: String) -> void:
	if sfx_manager != null and is_instance_valid(sfx_manager) and sfx_manager.has_method("play_sfx"):
		sfx_manager.play_sfx(name)


func set_sfx_enabled(enabled: bool) -> void:
	if sfx_manager != null and is_instance_valid(sfx_manager) and sfx_manager.has_method("set_enabled"):
		sfx_manager.set_enabled(enabled)


func set_sfx_volume(value: float) -> void:
	if sfx_manager != null and is_instance_valid(sfx_manager) and sfx_manager.has_method("set_volume"):
		sfx_manager.set_volume(value)


func spawn_xp_popup(amount: int, world_position: Vector2) -> void:
	if amount <= 0:
		return
	if feedback_layer == null or not is_instance_valid(feedback_layer):
		return
	if XpPopupScene == null:
		return
	var popup := XpPopupScene.instantiate()
	feedback_layer.add_child(popup)
	if popup.has_method("setup"):
		popup.setup(amount, world_position)


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


func _on_player_weapon_changed(weapon_data) -> void:
	ui.set_weapon(weapon_data)


func _on_player_died() -> void:
	run_state = "dead"
	player.set_control_enabled(false)
	if current_level != null and current_level.has_method("set_active"):
		current_level.set_active(false)
	set_combat_music_active(false)
	ui.show_death_screen()


func _refresh_direction_debug_draw() -> void:
	if player != null and is_instance_valid(player) and player.has_method("refresh_direction_debug_draw"):
		player.refresh_direction_debug_draw()


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


func has_current_level_amulet() -> bool:
	return player != null and player.has_amulet


func _clear_world_entities() -> void:
	for child in entity_layer.get_children():
		if child == player:
			continue
		child.queue_free()
