extends Node
class_name SoundThemeManager

const SILENT_DB := -80.0

@export var music_enabled: bool = true
@export_range(-60.0, 0.0, 0.5) var music_volume_db: float = -8.0
@export_range(0.1, 5.0, 0.1) var crossfade_duration: float = 1.25
@export_range(0.5, 10.0, 0.1) var calm_timeout: float = 3.0

var level_theme: AudioStream = null
var action_theme: AudioStream = null
var _in_action_state: bool = false
var _active_player: AudioStreamPlayer = null
var _fade_tween: Tween = null
var _missing_theme_logged: Dictionary = {}

@onready var music_a: AudioStreamPlayer = $MusicA
@onready var music_b: AudioStreamPlayer = $MusicB
@onready var calm_timer: Timer = $CalmTimer


func _ready() -> void:
	_active_player = music_a
	music_a.bus = "Master"
	music_b.bus = "Master"
	music_a.volume_db = SILENT_DB
	music_b.volume_db = SILENT_DB
	calm_timer.wait_time = calm_timeout
	calm_timer.one_shot = true


func set_level_themes(new_level_theme: AudioStream, new_action_theme: AudioStream) -> void:
	level_theme = new_level_theme
	action_theme = new_action_theme
	_missing_theme_logged.clear()
	_apply_target_theme(true)


func enter_action_state() -> void:
	calm_timer.stop()
	if _in_action_state:
		return
	_in_action_state = true
	_apply_target_theme()


func exit_action_state() -> void:
	if not _in_action_state:
		return
	calm_timer.start(calm_timeout)


func stop_music() -> void:
	calm_timer.stop()
	_stop_fade()
	for player in [music_a, music_b]:
		player.stop()
		player.stream = null
		player.volume_db = SILENT_DB
	_active_player = music_a


func set_music_enabled(enabled: bool) -> void:
	if music_enabled == enabled:
		return
	music_enabled = enabled
	if not music_enabled:
		stop_music()
		return
	_apply_target_theme(true)


func is_in_action_state() -> bool:
	return _in_action_state


func _apply_target_theme(force_restart: bool = false) -> void:
	if not music_enabled:
		stop_music()
		return

	var target_stream: AudioStream = _get_preferred_stream()
	if target_stream == null:
		if force_restart or (_active_player != null and _active_player.playing):
			_crossfade_to_stream(null)
		return

	if not force_restart and _active_player != null and _active_player.playing and _active_player.stream == target_stream:
		return

	_crossfade_to_stream(target_stream)


func _get_preferred_stream() -> AudioStream:
	if _in_action_state:
		if action_theme != null:
			return action_theme
		_log_missing_theme_once("action")
		if level_theme != null:
			return level_theme
		_log_missing_theme_once("level")
		return null

	if level_theme != null:
		return level_theme
	_log_missing_theme_once("level")
	return null


func _crossfade_to_stream(next_stream: AudioStream) -> void:
	_stop_fade()

	var outgoing_player: AudioStreamPlayer = _active_player
	var incoming_player: AudioStreamPlayer = music_b if _active_player == music_a else music_a

	if next_stream == null:
		if outgoing_player == null or not outgoing_player.playing:
			return
		_fade_players(null, outgoing_player)
		return

	incoming_player.stream = next_stream
	incoming_player.volume_db = SILENT_DB
	incoming_player.play()
	_active_player = incoming_player
	_fade_players(incoming_player, outgoing_player)


func _fade_players(fade_in_player: AudioStreamPlayer, fade_out_player: AudioStreamPlayer) -> void:
	_fade_tween = create_tween()
	_fade_tween.set_parallel(true)

	if fade_in_player != null:
		_fade_tween.tween_property(fade_in_player, "volume_db", music_volume_db, crossfade_duration)
	if fade_out_player != null:
		_fade_tween.tween_property(fade_out_player, "volume_db", SILENT_DB, crossfade_duration)

	_fade_tween.finished.connect(func() -> void:
		if fade_out_player != null:
			fade_out_player.stop()
			fade_out_player.stream = null
			fade_out_player.volume_db = SILENT_DB
		if fade_in_player == null:
			_active_player = music_a
		_fade_tween = null
	)


func _stop_fade() -> void:
	if _fade_tween != null and is_instance_valid(_fade_tween):
		_fade_tween.kill()
		_fade_tween = null


func _log_missing_theme_once(slot: String) -> void:
	if _missing_theme_logged.has(slot):
		return
	_missing_theme_logged[slot] = true
	print("SoundThemeManager: no %s theme configured; using silence/fallback." % slot)


func _on_calm_timer_timeout() -> void:
	if not _in_action_state:
		return
	_in_action_state = false
	_apply_target_theme()
