extends Node2D

const TEST_RENDER_ORIGIN := Vector2(960.0, 540.0)

@onready var player: CharacterBody2D = $Player
@onready var enemy: CharacterBody2D = $Enemy
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	player.global_position = Vector2.ZERO
	player.set_render_origin(TEST_RENDER_ORIGIN)

	enemy.global_position = Vector2(32.0, 0.0)
	enemy.setup("zombie", self, {})
	enemy.set_render_origin(TEST_RENDER_ORIGIN)

	_update_camera()


func _process(_delta: float) -> void:
	_update_camera()


func _update_camera() -> void:
	camera.global_position = player.get_visual_position()
