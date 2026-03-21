extends RefCounted
class_name CharacterVisuals

const VISUALS := {
	"player": {
		"texture": preload("res://assets/textures/characters/player_warrior.svg"),
		"draw_size": Vector2(40, 50),
		"anchor_offset": Vector2(-20, -42),
		"shadow_size": Vector2(24, 8),
		"shadow_offset": Vector2(-12, 8),
		"weapon_anchor": Vector2(8, -10)
	},
	"zombie": {
		"texture": preload("res://assets/textures/characters/zombie.svg"),
		"draw_size": Vector2(42, 52),
		"anchor_offset": Vector2(-21, -44),
		"shadow_size": Vector2(24, 8),
		"shadow_offset": Vector2(-12, 8)
	},
	"skeleton": {
		"texture": preload("res://assets/textures/characters/skeleton.svg"),
		"draw_size": Vector2(38, 50),
		"anchor_offset": Vector2(-19, -42),
		"shadow_size": Vector2(22, 7),
		"shadow_offset": Vector2(-11, 8)
	},
	"boss": {
		"texture": preload("res://assets/textures/characters/boss_guardian.svg"),
		"draw_size": Vector2(58, 68),
		"anchor_offset": Vector2(-29, -58),
		"shadow_size": Vector2(34, 10),
		"shadow_offset": Vector2(-17, 10)
	}
}


static func has_visual(visual_id: String) -> bool:
	return VISUALS.has(visual_id)


static func get_texture(visual_id: String) -> Texture2D:
	if not VISUALS.has(visual_id):
		return null
	return VISUALS[visual_id]["texture"]


static func get_draw_rect(visual_id: String, base: Vector2) -> Rect2:
	var entry: Dictionary = VISUALS.get(visual_id, {})
	var size: Vector2 = entry.get("draw_size", Vector2(40, 50))
	var anchor_offset: Vector2 = entry.get("anchor_offset", Vector2(-size.x * 0.5, -size.y + 8.0))
	return Rect2(base + anchor_offset, size)


static func get_shadow_rect(visual_id: String, base: Vector2) -> Rect2:
	var entry: Dictionary = VISUALS.get(visual_id, {})
	var shadow_size: Vector2 = entry.get("shadow_size", Vector2(22, 7))
	var shadow_offset: Vector2 = entry.get("shadow_offset", Vector2(-shadow_size.x * 0.5, 8.0))
	return Rect2(base + shadow_offset, shadow_size)


static func get_visual_size(visual_id: String) -> Vector2:
	var entry: Dictionary = VISUALS.get(visual_id, {})
	return entry.get("draw_size", Vector2(40, 50))


static func get_weapon_anchor(visual_id: String, base: Vector2) -> Vector2:
	var entry: Dictionary = VISUALS.get(visual_id, {})
	return base + entry.get("weapon_anchor", Vector2.ZERO)
