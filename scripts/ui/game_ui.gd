extends CanvasLayer

signal restart_requested
signal quit_requested
signal difficulty_selected(difficulty_id: String, multiplier: float)

const ItemVisuals := preload("res://scripts/visual/item_visuals.gd")
const WeaponDB := preload("res://data/weapons/weapon_db.gd")

var level_title_timer := 0.0
var pickup_message_timer := 0.0

@onready var hp_bar_wrap: Control = $HUD/Panel/MarginContainer/VBoxContainer/HPBarWrap
@onready var hp_bar_under: ColorRect = $HUD/Panel/MarginContainer/VBoxContainer/HPBarWrap/HPBarUnder
@onready var hp_fill_clip: Control = $HUD/Panel/MarginContainer/VBoxContainer/HPBarWrap/HPFillClip
@onready var hp_bar_fill: ColorRect = $HUD/Panel/MarginContainer/VBoxContainer/HPBarWrap/HPFillClip/HPBarFill
@onready var hp_label: Label = $HUD/Panel/MarginContainer/VBoxContainer/HPLabel
@onready var hud_root: Control = $HUD
@onready var top_right_root: Control = $TopRight
@onready var weapon_icon: TextureRect = $TopRight/Panel/MarginContainer/VBoxContainer/WeaponIcon
@onready var weapon_label: Label = $TopRight/Panel/MarginContainer/VBoxContainer/WeaponLabel
@onready var amulet_icon: TextureRect = $TopRight/Panel/MarginContainer/VBoxContainer/AmuletIcon
@onready var level_title: Label = $LevelTitle
@onready var hint_label: Label = $HintLabel
@onready var message_label: Label = $MessageLabel
@onready var death_screen: Control = $DeathScreen
@onready var victory_screen: Control = $VictoryScreen
@onready var difficulty_screen: Control = $DifficultyScreen
@onready var crosshair: Sprite2D = $Crosshair


func _ready() -> void:
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
	$DifficultyScreen/Panel/VBoxContainer/EasyButton.pressed.connect(func() -> void:
		difficulty_screen.visible = false
		emit_signal("difficulty_selected", "easy", 0.5)
	)
	$DifficultyScreen/Panel/VBoxContainer/NormalButton.pressed.connect(func() -> void:
		difficulty_screen.visible = false
		emit_signal("difficulty_selected", "normal", 1.0)
	)
	$DifficultyScreen/Panel/VBoxContainer/HardButton.pressed.connect(func() -> void:
		difficulty_screen.visible = false
		emit_signal("difficulty_selected", "hard", 1.5)
	)
	_set_mouse_passthrough(hud_root)
	_set_mouse_passthrough(top_right_root)
	_set_mouse_passthrough(hint_label)
	_set_mouse_passthrough(message_label)
	_set_mouse_passthrough(level_title)
	hp_bar_under.color = Color8(96, 53, 53)
	hp_bar_fill.color = Color8(245, 42, 16)
	weapon_icon.mouse_filter = Control.MOUSE_FILTER_STOP
	weapon_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	weapon_icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	weapon_icon.custom_minimum_size = Vector2(120, 120)
	weapon_label.visible = false
	amulet_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hp_label.visible = false
	set_weapon(WeaponDB.get_weapon(WeaponDB.get_default_weapon_id()))
	amulet_icon.texture = ItemVisuals.get_amulet_icon()
	set_amulet_collected(false)
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


func hide_overlays() -> void:
	death_screen.visible = false
	victory_screen.visible = false
	difficulty_screen.visible = false
	level_title.visible = false
	hint_label.visible = false
	message_label.visible = false
	_update_crosshair_visibility()


func set_hp(current_hp: int, max_hp: int) -> void:
	var ratio: float = 0.0 if max_hp <= 0 else clampf(float(current_hp) / float(max_hp), 0.0, 1.0)
	_set_hp_fill_ratio(ratio)
	hp_label.text = "HP %d / %d" % [current_hp, max_hp]


func set_weapon(weapon_data) -> void:
	var resolved_weapon = weapon_data if weapon_data != null else WeaponDB.get_default_weapon()
	weapon_label.text = resolved_weapon.display_name if resolved_weapon != null else "Dolch"
	weapon_icon.texture = resolved_weapon.icon if resolved_weapon != null and resolved_weapon.icon != null else ItemVisuals.get_weapon_icon(WeaponDB.get_default_weapon_id())
	weapon_icon.tooltip_text = weapon_label.text


func set_amulet_collected(collected: bool) -> void:
	amulet_icon.visible = collected


func show_level_title_text(text: String) -> void:
	level_title.text = text
	level_title_timer = 2.2
	level_title.modulate.a = 1.0
	level_title.visible = true


func show_interaction_hint(text: String) -> void:
	hint_label.text = text
	hint_label.visible = not text.is_empty()


func show_pickup_message(text: String) -> void:
	if text.is_empty():
		return
	message_label.text = text
	message_label.visible = true
	pickup_message_timer = 1.7


func show_death_screen() -> void:
	death_screen.visible = true
	victory_screen.visible = false
	show_interaction_hint("")
	_update_crosshair_visibility()


func show_victory_screen() -> void:
	victory_screen.visible = true
	death_screen.visible = false
	show_interaction_hint("")
	_update_crosshair_visibility()


func show_difficulty_screen() -> void:
	hide_overlays()
	difficulty_screen.visible = true
	_update_crosshair_visibility()


func _update_crosshair_visibility() -> void:
	var overlays_visible: bool = death_screen.visible or victory_screen.visible or difficulty_screen.visible
	var mouse_inside_viewport: bool = get_viewport().get_visible_rect().has_point(get_viewport().get_mouse_position())
	var show_crosshair: bool = not overlays_visible and mouse_inside_viewport
	crosshair.visible = show_crosshair
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN if show_crosshair else Input.MOUSE_MODE_VISIBLE)


func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _refresh_hp_fill() -> void:
	var hp_text: String = hp_label.text.strip_edges()
	var values: PackedStringArray = hp_text.trim_prefix("HP ").split("/")
	if values.size() != 2:
		_set_hp_fill_ratio(1.0)
		return
	var current_hp: int = int(values[0].strip_edges())
	var max_hp: int = max(1, int(values[1].strip_edges()))
	_set_hp_fill_ratio(clampf(float(current_hp) / float(max_hp), 0.0, 1.0))


func _set_hp_fill_ratio(ratio: float) -> void:
	var full_width: float = hp_bar_wrap.size.x if hp_bar_wrap.size.x > 0.0 else hp_bar_wrap.custom_minimum_size.x
	if full_width <= 0.0:
		full_width = 240.0
	hp_fill_clip.offset_right = full_width * clampf(ratio, 0.0, 1.0)


func _set_mouse_passthrough(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in control.get_children():
		if child is Control:
			_set_mouse_passthrough(child as Control)
