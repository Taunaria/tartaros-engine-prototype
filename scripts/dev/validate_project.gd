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
const CharacterVisuals = preload("res://scripts/visual/character_visuals.gd")

const VISUAL_IDS := ["player", "zombie", "skeleton", "boss"]
const DIRECTION_IDS := ["up", "down", "left", "right", "up_left", "up_right", "down_left", "down_right"]
const STATE_IDS := ["idle", "walk", "attack", "hit", "death"]


func _initialize() -> void:
	var game := GameScene.instantiate()
	get_root().add_child(game)
	var validation_failed: bool = _validate_character_animation_frames()
	call_deferred("quit", 1 if validation_failed else 0)


func _validate_character_animation_frames() -> bool:
	var validation_failed: bool = false
	for visual_id in VISUAL_IDS:
		for direction_id in DIRECTION_IDS:
			for state_id in STATE_IDS:
				var frame_count: int = CharacterVisuals.get_animation_frame_count(visual_id, direction_id, state_id)
				if state_id == "walk":
					if frame_count < 2:
						push_error("Missing walk animation frames for %s %s" % [visual_id, CharacterVisuals.get_animation_name(state_id, direction_id)])
						validation_failed = true
				elif frame_count < 1:
					push_error("Missing animation frame for %s %s" % [visual_id, CharacterVisuals.get_animation_name(state_id, direction_id)])
					validation_failed = true
	return validation_failed
