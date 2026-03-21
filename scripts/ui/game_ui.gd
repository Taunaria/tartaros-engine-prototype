extends CanvasLayer

signal restart_requested
signal quit_requested
signal difficulty_selected(difficulty_id: String, multiplier: float)

var level_title_timer := 0.0
var pickup_message_timer := 0.0

@onready var hp_bar: ProgressBar = $HUD/Panel/MarginContainer/VBoxContainer/HPBar
@onready var hp_label: Label = $HUD/Panel/MarginContainer/VBoxContainer/HPLabel
@onready var weapon_label: Label = $HUD/Panel/MarginContainer/VBoxContainer/WeaponLabel
@onready var level_title: Label = $LevelTitle
@onready var hint_label: Label = $HintLabel
@onready var message_label: Label = $MessageLabel
@onready var death_screen: Control = $DeathScreen
@onready var victory_screen: Control = $VictoryScreen
@onready var difficulty_screen: Control = $DifficultyScreen


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
	hide_overlays()


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


func hide_overlays() -> void:
	death_screen.visible = false
	victory_screen.visible = false
	difficulty_screen.visible = false
	level_title.visible = false
	hint_label.visible = false
	message_label.visible = false


func set_hp(current_hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_label.text = "HP %d / %d" % [current_hp, max_hp]


func set_weapon(weapon_name: String) -> void:
	weapon_label.text = "Waffe: %s" % weapon_name


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


func show_victory_screen() -> void:
	victory_screen.visible = true
	death_screen.visible = false
	show_interaction_hint("")


func show_difficulty_screen() -> void:
	hide_overlays()
	difficulty_screen.visible = true
