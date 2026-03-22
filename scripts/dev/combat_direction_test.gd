extends Node2D

const CombatDebug := preload("res://scripts/core/combat_debug.gd")
const EnemyScene := preload("res://scenes/enemies/Enemy.tscn")
const TEST_RENDER_ORIGIN := Vector2(960.0, 540.0)
const TEST_DISTANCE := 32.0

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	CombatDebug.enabled = true
	player.global_position = Vector2.ZERO
	player.debug_attack = true
	player.set_render_origin(TEST_RENDER_ORIGIN)
	_spawn_enemy(Vector2.LEFT, "EnemyLeft")
	_spawn_enemy(Vector2.RIGHT, "EnemyRight")
	_spawn_enemy(Vector2.UP, "EnemyUp")
	_spawn_enemy(Vector2.DOWN, "EnemyDown")
	_spawn_enemy(Vector2(-1.0, -1.0).normalized(), "EnemyUpLeft")
	_spawn_enemy(Vector2(1.0, -1.0).normalized(), "EnemyUpRight")
	_spawn_enemy(Vector2(-1.0, 1.0).normalized(), "EnemyDownLeft")
	_spawn_enemy(Vector2(1.0, 1.0).normalized(), "EnemyDownRight")
	_update_camera()


func _process(_delta: float) -> void:
	_update_camera()


func _spawn_enemy(direction: Vector2, enemy_name: String) -> void:
	var enemy: CharacterBody2D = EnemyScene.instantiate()
	enemy.name = enemy_name
	enemy.global_position = direction * TEST_DISTANCE
	add_child(enemy)
	enemy.setup("zombie", self, {})
	enemy.set_render_origin(TEST_RENDER_ORIGIN)
	enemy.set_active(false)


func _update_camera() -> void:
	camera.global_position = player.get_visual_position()
