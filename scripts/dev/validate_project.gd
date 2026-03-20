extends SceneTree

const GameScene = preload("res://scenes/game/Game.tscn")
const LevelScene = preload("res://scenes/levels/Level.tscn")
const PlayerScene = preload("res://scenes/player/Player.tscn")
const EnemyScene = preload("res://scenes/enemies/Enemy.tscn")
const ChestScene = preload("res://scenes/props/Chest.tscn")
const ExitScene = preload("res://scenes/props/ExitPortal.tscn")
const PickupScene = preload("res://scenes/props/WeaponPickup.tscn")
const UIScene = preload("res://scenes/ui/GameUI.tscn")
const BlockTileScene = preload("res://scenes/visual/BlockTile.tscn")
const EntityMarkerScene = preload("res://scenes/visual/EntityMarker.tscn")
const BlockRenderTestScene = preload("res://scenes/visual/BlockRenderTest.tscn")


func _initialize() -> void:
	var game := GameScene.instantiate()
	get_root().add_child(game)
	call_deferred("quit")
