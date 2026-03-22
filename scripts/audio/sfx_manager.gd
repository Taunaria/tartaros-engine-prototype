extends Node
class_name SfxManager

const SILENT_DB := -80.0
const DEFAULT_POOL_SIZE := 4
const DEFAULT_SOUND_PATHS := {
	"attack": "res://assets/audio/sfx/player/sfx_player_attack.wav",
	"hit": "res://assets/audio/sfx/enemies/sfx_zombie_hit_heavy.wav",
	"player_hit": "res://assets/audio/sfx/player/sfx_player_hit.wav",
	"enemy_die": "res://assets/audio/sfx/enemies/sfx_zombie_die.wav",
	"chest_open": "res://assets/audio/sfx/world/sfx_portal_activate.wav",
	"pickup": "res://assets/audio/sfx/world/sfx_pickup.flac"
}

@export var enabled: bool = true
@export_range(-60.0, 0.0, 0.5) var volume_db: float = -8.0
@export_range(0.0, 0.15, 0.005) var random_pitch_variation: float = 0.06
@export_range(0.0, 2.0, 0.05) var random_volume_variation_db: float = 0.6
@export_range(0.02, 0.35, 0.01) var default_cooldown: float = 0.08

var _streams: Dictionary = {}
var _last_played: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for index in range(DEFAULT_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % index
		player.bus = "Master"
		player.volume_db = SILENT_DB
		add_child(player)
		_players.append(player)


func play_sfx(name: String) -> void:
	if not enabled or name.is_empty():
		return

	var stream: AudioStream = _get_stream(name)
	if stream == null:
		return

	var now: float = Time.get_ticks_msec() * 0.001
	var cooldown: float = _get_cooldown(name)
	var last_played: float = float(_last_played.get(name, -9999.0))
	if now - last_played < cooldown:
		return

	var player: AudioStreamPlayer = _get_free_player()
	if player == null:
		return

	player.stop()
	player.stream = stream
	player.volume_db = volume_db + randf_range(-random_volume_variation_db, random_volume_variation_db)
	player.pitch_scale = 1.0 + randf_range(-random_pitch_variation, random_pitch_variation)
	player.play()
	_last_played[name] = now


func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		_stop_all()


func set_volume(value: float) -> void:
	volume_db = value


func _get_stream(name: String) -> AudioStream:
	if _streams.has(name):
		return _streams[name]

	var path: String = DEFAULT_SOUND_PATHS.get(name, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		_streams[name] = null
		return null

	var stream: AudioStream = load(path)
	_streams[name] = stream
	return stream


func _get_cooldown(name: String) -> float:
	match name:
		"attack":
			return 0.05
		"hit":
			return 0.07
		"player_hit":
			return 0.12
		"enemy_die":
			return 0.12
		"chest_open":
			return 0.18
		"pickup":
			return 0.08
		_:
			return default_cooldown


func _get_free_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	return null


func _stop_all() -> void:
	for player in _players:
		player.stop()
		player.stream = null
		player.volume_db = SILENT_DB

