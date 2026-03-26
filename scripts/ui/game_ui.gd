extends CanvasLayer

signal restart_requested
signal quit_requested
signal difficulty_selected(difficulty_id: String, multiplier: float)
signal resume_requested

const ItemVisuals := preload("res://scripts/visual/item_visuals.gd")
const WeaponDB := preload("res://data/weapons/weapon_db.gd")
const CombatDebug := preload("res://scripts/core/combat_debug.gd")
const IsoMapper := preload("res://scripts/core/iso.gd")

var level_title_timer := 0.0
var pickup_message_timer := 0.0
var game_ref: Node = null
var mobile_platform: bool = OS.has_feature("mobile") or OS.has_feature("ios")

@onready var hp_bar_wrap: Control = $HUD/Panel/MarginContainer/VBoxContainer/HPBarWrap
@onready var hp_bar_under: ColorRect = $HUD/Panel/MarginContainer/VBoxContainer/HPBarWrap/HPBarUnder
@onready var hp_fill_clip: Control = $HUD/Panel/MarginContainer/VBoxContainer/HPBarWrap/HPFillClip
@onready var hp_bar_fill: ColorRect = $HUD/Panel/MarginContainer/VBoxContainer/HPBarWrap/HPFillClip/HPBarFill
@onready var hp_label: Label = $HUD/Panel/MarginContainer/VBoxContainer/HPBarWrap/HPLabel
@onready var start_screen_background: TextureRect = $StartScreenBackground
@onready var hud_root: Control = $HUD
@onready var top_right_root: Control = $TopRight
@onready var weapon_icon: TextureRect = $TopRight/Panel/MarginContainer/VBoxContainer/WeaponIcon
@onready var weapon_label: Label = $TopRight/Panel/MarginContainer/VBoxContainer/WeaponLabel
@onready var gold_label: Label = $TopRight/Panel/MarginContainer/VBoxContainer/GoldLabel
@onready var xp_label: Label = $TopRight/Panel/MarginContainer/VBoxContainer/XPLabel
@onready var amulet_icon: TextureRect = $TopRight/Panel/MarginContainer/VBoxContainer/AmuletIcon
@onready var level_title: Label = $LevelTitle
@onready var hint_label: Label = $HintLabel
@onready var message_label: Label = $MessageLabel
@onready var touch_controls_root: Control = $TouchControlsRoot
@onready var death_screen: Control = $DeathScreen
@onready var victory_screen: Control = $VictoryScreen
@onready var landing_screen: Control = $LandingScreen
@onready var main_menu: Control = $LandingScreen/Panel/MainMenu
@onready var difficulty_menu: Control = $LandingScreen/Panel/DifficultyMenu
@onready var resume_button: Button = $LandingScreen/Panel/MainMenu/VBoxContainer/ResumeButton
@onready var crosshair: Sprite2D = $Crosshair
@onready var debug_overlay: Control = $DebugOverlay
@onready var debug_view_arrow: TextureRect = $DebugOverlay/Panel/MarginContainer/VBoxContainer/ViewRow/ViewArrow
@onready var debug_view_label: Label = $DebugOverlay/Panel/MarginContainer/VBoxContainer/ViewRow/ViewLabel
@onready var debug_attack_arrow: TextureRect = $DebugOverlay/Panel/MarginContainer/VBoxContainer/AttackRow/AttackArrow
@onready var debug_attack_label: Label = $DebugOverlay/Panel/MarginContainer/VBoxContainer/AttackRow/AttackLabel
@onready var debug_key_icon: TextureRect = $DebugOverlay/Panel/MarginContainer/VBoxContainer/KeyRow/KeyIcon
@onready var debug_key_label: Label = $DebugOverlay/Panel/MarginContainer/VBoxContainer/KeyRow/KeyLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$DeathScreen/Panel/VBoxContainer/RestartButton.pressed.connect(func() -> void:
		emit_signal("restart_requested")
	)
	$DeathScreen/Panel/VBoxContainer/QuitButton.pressed.connect(func() -> void:
		emit_signal("quit_requested")
	)
	$VictoryScreen/Panel/VBoxContainer/RestartButton.pressed.connect(func() -> void:
		emit_signal("restart_requested")
	)
	$VictoryScreen/Panel/VBoxContainer/QuitButton.pressed.connect(func() -> void:
		emit_signal("quit_requested")
	)
	$LandingScreen/Panel/MainMenu/VBoxContainer/NewGameButton.pressed.connect(func() -> void:
		show_difficulty_screen()
	)
	$LandingScreen/Panel/MainMenu/VBoxContainer/ResumeButton.pressed.connect(func() -> void:
		if resume_button.disabled:
			return
		emit_signal("resume_requested")
	)
	$LandingScreen/Panel/MainMenu/VBoxContainer/QuitButton.pressed.connect(func() -> void:
		emit_signal("quit_requested")
	)
	$LandingScreen/Panel/DifficultyMenu/VBoxContainer/EasyButton.pressed.connect(func() -> void:
		landing_screen.visible = false
		emit_signal("difficulty_selected", "easy", 0.5)
	)
	$LandingScreen/Panel/DifficultyMenu/VBoxContainer/NormalButton.pressed.connect(func() -> void:
		landing_screen.visible = false
		emit_signal("difficulty_selected", "normal", 1.0)
	)
	$LandingScreen/Panel/DifficultyMenu/VBoxContainer/HardButton.pressed.connect(func() -> void:
		landing_screen.visible = false
		emit_signal("difficulty_selected", "hard", 1.5)
	)
	$LandingScreen/Panel/DifficultyMenu/VBoxContainer/BackButton.pressed.connect(func() -> void:
		_show_main_menu(not resume_button.disabled)
	)
	_set_mouse_passthrough(hud_root)
	_set_mouse_passthrough(top_right_root)
	_set_mouse_passthrough(hint_label)
	_set_mouse_passthrough(message_label)
	_set_mouse_passthrough(level_title)
	hp_bar_under.color = Color8(96, 53, 53)
	hp_bar_fill.color = Color8(245, 42, 16)
	hp_bar_wrap.resized.connect(_refresh_hp_fill)
	weapon_icon.mouse_filter = Control.MOUSE_FILTER_STOP
	weapon_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	weapon_icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	weapon_icon.custom_minimum_size = Vector2(120, 120)
	weapon_label.visible = false
	amulet_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	amulet_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	amulet_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	amulet_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	amulet_icon.custom_minimum_size = Vector2(42, 42)
	hp_label.visible = true
	set_gold(0)
	set_xp(0)
	set_weapon(WeaponDB.get_weapon(WeaponDB.get_default_weapon_id()))
	amulet_icon.texture = ItemVisuals.get_amulet_icon()
	set_amulet_collected(false)
	if touch_controls_root != null and touch_controls_root.has_method("set_mobile_enabled"):
		touch_controls_root.set_mobile_enabled(mobile_platform)
	_configure_direction_debug_overlay()
	hide_overlays()
	call_deferred("_refresh_hp_fill")


func _process(delta: float) -> void:
	if level_title_timer > 0.0:
		level_title_timer -= delta
		level_title.modulate.a = min(level_title_timer * 1.5, 1.0)
		if level_title_timer <= 0.0:
			level_title.visible = false

	if pickup_message_timer > 0.0:
		pickup_message_timer -= delta
		if pickup_message_timer <= 0.0:
			message_label.visible = false
	_update_crosshair_visibility()
	_update_direction_debug_overlay()


func hide_overlays() -> void:
	death_screen.visible = false
	victory_screen.visible = false
	landing_screen.visible = false
	start_screen_background.visible = false
	level_title.visible = false
	hint_label.visible = false
	message_label.visible = false
	_set_touch_controls_active(false)
	_update_crosshair_visibility()


func set_hp(current_hp: int, max_hp: int) -> void:
	var ratio: float = 0.0 if max_hp <= 0 else clampf(float(current_hp) / float(max_hp), 0.0, 1.0)
	_set_hp_fill_ratio(ratio)
	hp_label.text = "%d/%d" % [current_hp, max_hp]


func set_weapon(weapon_data) -> void:
	var resolved_weapon = weapon_data if weapon_data != null else WeaponDB.get_default_weapon()
	var weapon_id: String = WeaponDB.get_default_weapon_id()
	if resolved_weapon != null and "id" in resolved_weapon and not String(resolved_weapon.id).is_empty():
		weapon_id = String(resolved_weapon.id)
	weapon_label.text = resolved_weapon.display_name if resolved_weapon != null else "Dolch"
	var resolved_texture: Texture2D = ItemVisuals.get_weapon_icon(weapon_id)
	if resolved_texture == null and resolved_weapon != null and resolved_weapon.icon != null:
		resolved_texture = resolved_weapon.icon
	weapon_icon.texture = resolved_texture
	weapon_icon.tooltip_text = weapon_label.text


func set_amulet_collected(collected: bool) -> void:
	amulet_icon.visible = collected


func set_gold(amount: int) -> void:
	gold_label.text = "Gold %d" % max(amount, 0)


func set_xp(amount: int) -> void:
	xp_label.text = "XP %d" % max(amount, 0)


func show_level_title_text(text: String) -> void:
	level_title.text = text
	level_title_timer = 2.2
	level_title.modulate.a = 1.0
	level_title.visible = true


func show_interaction_hint(_text: String) -> void:
	hint_label.text = ""
	hint_label.visible = false


func show_pickup_message(text: String) -> void:
	if text.is_empty():
		return
	message_label.text = text
	message_label.visible = true
	pickup_message_timer = 1.7


func show_death_screen() -> void:
	death_screen.visible = true
	victory_screen.visible = false
	_set_touch_controls_active(false)
	show_interaction_hint("")
	_update_crosshair_visibility()


func show_victory_screen() -> void:
	victory_screen.visible = true
	death_screen.visible = false
	_set_touch_controls_active(false)
	show_interaction_hint("")
	_update_crosshair_visibility()


func show_landing_screen(can_resume: bool = false) -> void:
	hide_overlays()
	hud_root.visible = false
	top_right_root.visible = false
	landing_screen.visible = true
	start_screen_background.visible = true
	_show_main_menu(can_resume)
	_update_crosshair_visibility()


func show_difficulty_screen() -> void:
	hide_overlays()
	hud_root.visible = false
	top_right_root.visible = false
	landing_screen.visible = true
	start_screen_background.visible = true
	_show_difficulty_menu()
	_update_crosshair_visibility()


func show_gameplay_hud() -> void:
	landing_screen.visible = false
	start_screen_background.visible = false
	hud_root.visible = true
	top_right_root.visible = true
	_set_touch_controls_active(true)
	_update_crosshair_visibility()


func set_game_ref(new_game_ref: Node) -> void:
	game_ref = new_game_ref
	if game_ref != null and game_ref.has_method("is_mobile_platform"):
		mobile_platform = game_ref.is_mobile_platform()
	if crosshair != null and is_instance_valid(crosshair) and crosshair.has_method("set_game_ref"):
		crosshair.set_game_ref(game_ref)
	if touch_controls_root != null and is_instance_valid(touch_controls_root) and touch_controls_root.has_method("set_game_ref"):
		touch_controls_root.set_game_ref(game_ref)
	if touch_controls_root != null and is_instance_valid(touch_controls_root) and touch_controls_root.has_method("set_mobile_enabled"):
		touch_controls_root.set_mobile_enabled(mobile_platform)
	_update_crosshair_visibility()


func refresh_direction_debug_overlay() -> void:
	_update_direction_debug_overlay(true)


func _update_crosshair_visibility() -> void:
	var overlays_visible: bool = death_screen.visible or victory_screen.visible or landing_screen.visible
	if mobile_platform:
		crosshair.visible = not overlays_visible
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		return

	var show_crosshair: bool = not overlays_visible
	crosshair.visible = show_crosshair
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN if show_crosshair else Input.MOUSE_MODE_VISIBLE)


func _set_touch_controls_active(active: bool) -> void:
	if touch_controls_root == null or not is_instance_valid(touch_controls_root):
		return
	if touch_controls_root.has_method("set_gameplay_active"):
		touch_controls_root.set_gameplay_active(active and mobile_platform)
	else:
		touch_controls_root.visible = active and mobile_platform


func _configure_direction_debug_overlay() -> void:
	debug_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_mouse_passthrough(debug_overlay)
	debug_overlay.visible = false
	debug_view_arrow.texture = CombatDebug.get_direction_arrow_texture()
	debug_attack_arrow.texture = CombatDebug.get_direction_arrow_texture()
	debug_key_icon.texture = CombatDebug.get_keycap_texture()
	debug_view_arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	debug_attack_arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	debug_key_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	debug_view_arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	debug_attack_arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	debug_key_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	debug_view_arrow.modulate = Color8(72, 149, 255)
	debug_attack_arrow.modulate = Color8(255, 86, 92)
	debug_key_icon.modulate = Color8(238, 242, 250)
	_update_direction_debug_overlay(true)


func _update_direction_debug_overlay(force: bool = false) -> void:
	var enabled: bool = CombatDebug.direction_overlay_enabled
	if debug_overlay.visible != enabled:
		debug_overlay.visible = enabled
		force = true
	if not enabled and not force:
		return

	var view_direction_vector: Vector2 = Vector2.DOWN
	var attack_direction_vector: Vector2 = Vector2.DOWN
	var view_direction_id: String = "down"
	var attack_direction_id: String = "down"
	var last_input_label: String = CombatDebug.last_input_label
	var player := _get_player()
	if player != null and is_instance_valid(player) and player.has_method("get_debug_direction_info"):
		var direction_info: Dictionary = player.get_debug_direction_info()
		view_direction_vector = direction_info.get("view_direction_vector", view_direction_vector)
		attack_direction_vector = direction_info.get("attack_direction_vector", attack_direction_vector)
		view_direction_id = direction_info.get("view_direction_id", view_direction_id)
		attack_direction_id = direction_info.get("attack_direction_id", attack_direction_id)
		last_input_label = direction_info.get("last_input_label", last_input_label)

	debug_view_label.text = "Blickrichtung: %s" % view_direction_id
	debug_attack_label.text = "Attacke Richtung: %s" % attack_direction_id
	debug_key_label.text = "Letzte Tastenkombination: %s" % last_input_label
	debug_view_arrow.pivot_offset = _get_debug_icon_pivot(debug_view_arrow)
	debug_attack_arrow.pivot_offset = _get_debug_icon_pivot(debug_attack_arrow)
	debug_view_arrow.rotation = IsoMapper.logic_direction_to_screen(view_direction_vector).angle()
	debug_attack_arrow.rotation = IsoMapper.logic_direction_to_screen(attack_direction_vector).angle()


func _get_player() -> Node:
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0]


func _get_debug_icon_pivot(icon: Control) -> Vector2:
	var icon_size: Vector2 = icon.size
	if icon_size.length_squared() <= 0.001:
		icon_size = icon.custom_minimum_size
	return icon_size * 0.5


func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _refresh_hp_fill() -> void:
	var hp_text: String = hp_label.text.strip_edges()
	var values: PackedStringArray = hp_text.split("/")
	if values.size() != 2:
		_set_hp_fill_ratio(1.0)
		return
	var current_hp: int = int(values[0].strip_edges())
	var max_hp: int = max(1, int(values[1].strip_edges()))
	_set_hp_fill_ratio(clampf(float(current_hp) / float(max_hp), 0.0, 1.0))


func _set_hp_fill_ratio(ratio: float) -> void:
	var clamped_ratio: float = clampf(ratio, 0.0, 1.0)
	hp_fill_clip.anchor_left = 0.0
	hp_fill_clip.anchor_right = clamped_ratio
	hp_fill_clip.offset_left = 0.0
	hp_fill_clip.offset_right = 0.0


func _set_mouse_passthrough(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in control.get_children():
		if child is Control:
			_set_mouse_passthrough(child as Control)


func _show_main_menu(can_resume: bool) -> void:
	main_menu.visible = true
	difficulty_menu.visible = false
	resume_button.disabled = not can_resume
	if can_resume:
		resume_button.grab_focus()
	else:
		$LandingScreen/Panel/MainMenu/VBoxContainer/NewGameButton.grab_focus()


func _show_difficulty_menu() -> void:
	main_menu.visible = false
	difficulty_menu.visible = true
	$LandingScreen/Panel/DifficultyMenu/VBoxContainer/NormalButton.grab_focus()
