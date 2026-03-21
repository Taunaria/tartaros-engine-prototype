extends RefCounted
class_name CharacterVisuals

static var _texture_cache: Dictionary = {}

const VISUALS := {
	"player": {
		"texture_path": "res://assets/textures/characters/generated/player_warrior.png",
		"draw_size": Vector2(54, 68),
		"anchor_offset": Vector2(-27, -57),
		"shadow_size": Vector2(24, 8),
		"shadow_offset": Vector2(-12, 2),
		"weapon_anchor": Vector2(12, -18)
	},
	"zombie": {
		"texture_path": "res://assets/textures/characters/generated/zombie.png",
		"draw_size": Vector2(52, 68),
		"anchor_offset": Vector2(-26, -57),
		"shadow_size": Vector2(24, 8),
		"shadow_offset": Vector2(-12, 2)
	},
	"skeleton": {
		"texture_path": "res://assets/textures/characters/generated/skeleton.png",
		"draw_size": Vector2(50, 68),
		"anchor_offset": Vector2(-25, -57),
		"shadow_size": Vector2(22, 7),
		"shadow_offset": Vector2(-11, 2)
	},
	"boss": {
		"texture_path": "res://assets/textures/characters/generated/boss_guardian.png",
		"draw_size": Vector2(74, 86),
		"anchor_offset": Vector2(-37, -74),
		"shadow_size": Vector2(34, 10),
		"shadow_offset": Vector2(-17, 3)
	}
}


static func has_visual(visual_id: String) -> bool:
	return VISUALS.has(visual_id)


static func get_texture(visual_id: String) -> Texture2D:
	if not VISUALS.has(visual_id):
		return null
	var path: String = VISUALS[visual_id].get("texture_path", "")
	if path.is_empty():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path]
	var image := Image.new()
	var error: Error = image.load(ProjectSettings.globalize_path(path))
	if error != OK:
		push_warning("CharacterVisuals: failed to load texture %s" % path)
		return null
	var texture := ImageTexture.create_from_image(image)
	_texture_cache[path] = texture
	return texture


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
