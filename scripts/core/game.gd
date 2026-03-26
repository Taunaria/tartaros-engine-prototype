extends Node2D

const LevelData := preload("res://data/levels/level_data.gd")
const ItemDB := preload("res://data/items/item_db.gd")
const LevelScene := preload("res://scenes/levels/Level.tscn")
const GameCamera := preload("res://scripts/core/game_camera.gd")
const IsoMapper := preload("res://scripts/core/iso.gd")
const LevelMusicTheme := preload("res://scripts/audio/level_music_theme.gd")
const CombatDebug := preload("res://scripts/core/combat_debug.gd")
const SfxManager := preload("res://scripts/audio/sfx_manager.gd")
const XpPopupScene := preload("res://scenes/ui/XpPopup.tscn")

@export var level_music_themes: Array[LevelMusicTheme] = []

var levels: Array[Dictionary] = []
var current_level_index: int = 0
var current_level: Node = null
var run_state: String = "landing"
var combat_music_active: bool = false
var selected_difficulty_id: String = "normal"
var difficulty_multiplier: float = 1.0
var difficulty_selected: bool = false
var current_level_amulet_collected: bool = false
var level_transition_in_progress: bool = false
var total_xp: int = 0
var total_gold: int = 0
var mobile_platform: bool = OS.has_feature("mobile") or OS.has_feature("ios")
var touch_move_vector: Vector2 = Vector2.ZERO
var touch_aim_screen_position: Vector2 = Vector2.ZERO
var touch_attack_pressed: bool = false
var touch_attack_held: bool = false
var debug_last_transition_source_id: String = ""
var debug_last_transition_target_id: String = ""

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
	add_to_group("game")
	get_tree().paused = false
	camera.apply_defaults()
	levels = LevelData.get_levels()
	player.hp_changed.connect(_on_player_hp_changed)
	player.weapon_changed.connect(_on_player_weapon_changed)
	player.died.connect(_on_player_died)
	if player.has_method("set_game_ref"):
		player.set_game_ref(self)
	if ui != null and is_instance_valid(ui) and ui.has_method("set_game_ref"):
		ui.set_game_ref(self)
	ui.difficulty_selected.connect(_on_difficulty_selected)
	ui.resume_requested.connect(resume_run)
	ui.restart_requested.connect(start_new_run)
	ui.quit_requested.connect(_quit_game)
	ui.show_landing_screen(false)
	_sync_ui_state()


func _process(_delta: float) -> void:
	if is_instance_valid(player):
		camera_rig.global_position = player.get_visual_position()


func _unhandled_input(event: InputEvent) -> void:
	CombatDebug.register_last_input(event)

	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_ESCAPE or key_event.physical_keycode == KEY_ESCAPE:
			if run_state == "playing":
				pause_run()
				get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_F3 or key_event.physical_keycode == KEY_F3:
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
	get_tree().paused = false
	run_state = "playing"
	level_transition_in_progress = false
	current_level_amulet_collected = false
	total_xp = 0
	total_gold = 0
	reset_touch_input_state()
	player.reset_for_new_run()
	player.set_control_enabled(true)
	ui.hide_overlays()
	ui.show_gameplay_hud()
	current_level_index = 0
	set_combat_music_active(false)
	_load_level(current_level_index)


func get_difficulty_multiplier() -> float:
	return difficulty_multiplier


func get_difficulty_id() -> String:
	return selected_difficulty_id


func get_barrel_loot_config() -> Dictionary:
	match selected_difficulty_id:
		"easy":
			return {"count": 2, "gold_ratio": 0.65, "items_per_barrel": 3}
		"hard":
			return {"count": 6, "gold_ratio": 0.35, "items_per_barrel": 1}
		_:
			return {"count": 4, "gold_ratio": 0.5, "items_per_barrel": 2}


func is_mobile_platform() -> bool:
	return mobile_platform


func is_desktop_platform() -> bool:
	return OS.has_feature("desktop") or not mobile_platform


func set_touch_move_vector(move_vector: Vector2) -> void:
	if not mobile_platform:
		touch_move_vector = Vector2.ZERO
		return
	touch_move_vector = move_vector if move_vector.length_squared() <= 1.0 else move_vector.normalized()


func set_touch_aim_screen_position(screen_position: Vector2) -> void:
	if not mobile_platform:
		return
	touch_aim_screen_position = screen_position


func set_touch_attack_pressed() -> void:
	if not mobile_platform:
		return
	touch_attack_pressed = true


func set_touch_attack_held(held: bool) -> void:
	if not mobile_platform:
		touch_attack_held = false
		return
	touch_attack_held = held


func reset_touch_input_state() -> void:
	touch_move_vector = Vector2.ZERO
	touch_attack_pressed = false
	touch_attack_held = false
	touch_aim_screen_position = get_viewport_rect().size * 0.5


func get_move_vector() -> Vector2:
	if mobile_platform:
		return touch_move_vector
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)


func get_aim_screen_position() -> Vector2:
	if mobile_platform:
		return touch_aim_screen_position
	return get_viewport().get_mouse_position()


func get_aim_vector(reference_world_position: Vector2, render_origin: Vector2) -> Vector2:
	var aim_canvas_position: Vector2 = _get_aim_canvas_position()
	var aim_logic_position: Vector2 = IsoMapper.screen_to_logic(aim_canvas_position, render_origin)
	var aim_direction: Vector2 = aim_logic_position - reference_world_position
	if aim_direction.length_squared() > 0.001:
		return aim_direction.normalized()
	return Vector2.ZERO


func _get_aim_canvas_position() -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * get_aim_screen_position()


func get_attack_pressed() -> bool:
	if mobile_platform:
		var pressed: bool = touch_attack_pressed
		touch_attack_pressed = false
		return pressed
	return Input.is_action_just_pressed("attack")


func get_attack_held() -> bool:
	if mobile_platform:
		return touch_attack_held
	return Input.is_action_pressed("attack")


func advance_to_level(level_index: int) -> void:
	if run_state != "playing":
		return
	if level_transition_in_progress:
		return

	if level_index < 0 or level_index >= levels.size():
		complete_demo()
		return

	level_transition_in_progress = true
	current_level_index = level_index
	_load_level(current_level_index)
	call_deferred("_finish_level_transition")


func advance_to_level_via_portal(portal: Node, level_id: String) -> void:
	if portal == null or not is_instance_valid(portal):
		return
	if current_level == null or not is_instance_valid(current_level):
		return
	var current_exit_portal: Variant = null
	if current_level.has_method("get_exit_portal"):
		current_exit_portal = current_level.get_exit_portal()
	if current_exit_portal != portal:
		return
	debug_last_transition_source_id = _get_current_level_id()
	debug_last_transition_target_id = level_id
	_update_transition_debug_ui("portal")
	advance_to_level_id(level_id)


func advance_to_level_id(level_id: String) -> void:
	if level_id.is_empty():
		complete_demo()
		return
	advance_to_level(_get_level_index_by_id(level_id))


func _finish_level_transition() -> void:
	level_transition_in_progress = false


func give_reward(reward: Dictionary) -> Dictionary:
	var result: Dictionary = {
		"consumed": false,
		"stat_popup_text": "",
		"stat_popup_color": Color.WHITE
	}
	if reward.is_empty():
		return result

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
		result["consumed"] = true
		if healed_amount > 0:
			result["stat_popup_text"] = "+%d HP" % healed_amount
			result["stat_popup_color"] = Color(1.0, 0.86, 0.52, 1.0)
	elif reward_type == "heal":
		if player == null or not is_instance_valid(player) or player.hp >= player.max_hp:
			return result
		var healed_amount: int = player.heal(reward.get("amount", 0))
		ui.show_pickup_message("+%d HP" % healed_amount)
		play_sfx("pickup")
		result["consumed"] = healed_amount > 0
		if healed_amount > 0:
			result["stat_popup_text"] = "+%d HP" % healed_amount
			result["stat_popup_color"] = Color(0.64, 1.0, 0.7, 1.0)
	elif reward_type == "gold":
		var gold_amount: int = max(1, int(reward.get("amount", 1)))
		total_gold += gold_amount
		if ui != null and is_instance_valid(ui) and ui.has_method("set_gold"):
			ui.set_gold(total_gold)
		ui.show_pickup_message("+%d Gold" % gold_amount)
		play_sfx("pickup")
		result["consumed"] = true
		result["stat_popup_text"] = "+%d Gold" % gold_amount
		result["stat_popup_color"] = Color(1.0, 0.88, 0.38, 1.0)
	elif reward_type == "amulet" and item_data != null:
		player.obtain_amulet()
		current_level_amulet_collected = true
		ui.show_pickup_message(item_data.display_name if not item_data.display_name.is_empty() else reward.get("label", "Amulett erhalten"))
		ui.set_amulet_collected(true)
		play_sfx("pickup")
		if current_level != null and current_level.has_method("refresh_exit_state"):
			current_level.refresh_exit_state()
		result["consumed"] = true
	return result


func show_interaction_hint(text: String) -> void:
	ui.show_interaction_hint(text)


func complete_demo() -> void:
	get_tree().paused = false
	run_state = "victory"
	player.set_control_enabled(false)
	if current_level != null and current_level.has_method("set_active"):
		current_level.set_active(false)
	set_combat_music_active(false)
	ui.show_victory_screen()


func _load_level(level_index: int) -> void:
	_clear_world_entities()
	if current_level != null:
		if current_level.get_parent() == level_container:
			level_container.remove_child(current_level)
		current_level.queue_free()
		current_level = null

	current_level_amulet_collected = false
	set_combat_music_active(false)
	_apply_level_music_for(levels[level_index].get("id", ""))
	player.clear_amulet()
	ui.set_amulet_collected(false)

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
	_sync_ui_state(true)
	_update_transition_debug_ui("loaded")


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
	total_xp += amount
	if ui != null and is_instance_valid(ui) and ui.has_method("set_xp"):
		ui.set_xp(total_xp)
	if feedback_layer == null or not is_instance_valid(feedback_layer):
		return
	if XpPopupScene == null:
		return
	var popup := XpPopupScene.instantiate()
	feedback_layer.add_child(popup)
	if popup.has_method("setup"):
		popup.setup(amount, _logic_to_feedback_position(world_position))


func spawn_text_popup(text: String, world_position: Vector2, color: Color = Color.WHITE) -> void:
	if text.is_empty():
		return
	if feedback_layer == null or not is_instance_valid(feedback_layer):
		return
	if XpPopupScene == null:
		return
	var popup := XpPopupScene.instantiate()
	feedback_layer.add_child(popup)
	if popup.has_method("setup_text"):
		popup.setup_text(text, _logic_to_feedback_position(world_position), color)


func _logic_to_feedback_position(world_position: Vector2) -> Vector2:
	if current_level != null and is_instance_valid(current_level) and current_level.has_method("get_render_origin"):
		return IsoMapper.logic_to_screen(world_position, current_level.get_render_origin())
	return world_position


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
	get_tree().paused = false
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


func pause_run() -> void:
	if run_state != "playing":
		return
	run_state = "paused"
	reset_touch_input_state()
	ui.show_landing_screen(true)
	get_tree().paused = true


func resume_run() -> void:
	if run_state != "paused":
		return
	get_tree().paused = false
	run_state = "playing"
	reset_touch_input_state()
	ui.hide_overlays()
	ui.show_gameplay_hud()
	_sync_ui_state()


func _quit_game() -> void:
	get_tree().quit()


func _sync_ui_state(ensure_gameplay_hud: bool = false) -> void:
	if ui == null or not is_instance_valid(ui):
		return
	if ensure_gameplay_hud and run_state == "playing":
		ui.show_gameplay_hud()
	if player != null and is_instance_valid(player):
		ui.set_hp(player.hp, player.max_hp)
		ui.set_weapon(player.get_current_weapon())
	if ui.has_method("set_xp"):
		ui.set_xp(total_xp)
	if ui.has_method("set_gold"):
		ui.set_gold(total_gold)
	ui.set_amulet_collected(current_level_amulet_collected)
	_update_transition_debug_ui("sync")


func _get_level_index_by_id(level_id: String) -> int:
	for index in range(levels.size()):
		if String(levels[index].get("id", "")) == level_id:
			return index
	return -1


func _get_current_level_id() -> String:
	if current_level == null or not is_instance_valid(current_level):
		return ""
	if current_level_index < 0 or current_level_index >= levels.size():
		return ""
	return String(levels[current_level_index].get("id", ""))


func _update_transition_debug_ui(reason: String) -> void:
	if ui == null or not is_instance_valid(ui) or not ui.has_method("set_transition_debug_text"):
		return
	var current_level_id: String = _get_current_level_id()
	var text: String = ""
	match reason:
		"portal":
			text = "Portal: %s -> %s" % [debug_last_transition_source_id, debug_last_transition_target_id]
		"loaded":
			text = "Geladen: %s | Portal: %s -> %s" % [current_level_id, debug_last_transition_source_id, debug_last_transition_target_id]
		"sync":
			if current_level_id.is_empty():
				text = ""
			elif debug_last_transition_source_id.is_empty() and debug_last_transition_target_id.is_empty():
				text = "Aktiv: %s" % current_level_id
			else:
				text = "Aktiv: %s | Portal: %s -> %s" % [current_level_id, debug_last_transition_source_id, debug_last_transition_target_id]
		_:
			text = "Aktiv: %s" % current_level_id
	ui.set_transition_debug_text(text)
	print(text)


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
