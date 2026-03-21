extends RefCounted
class_name CharacterVisuals

static var _texture_cache: Dictionary = {}
static var _texture_analysis_cache: Dictionary = {}
const DIRECTION_IDS := ["dr", "ul", "ur", "dl"]
const STATE_IDS := ["idle", "attack"]

const VISUALS := {
	"player": {
		"default_texture_path": "res://assets/textures/characters/generated/player_warrior.png",
		"directional_prefix": "player",
		"draw_size": Vector2(54, 68),
		"body_draw_height": 58.0,
		"anchor_offset": Vector2(-27, -57),
		"shadow_size": Vector2(24, 8),
		"shadow_offset": Vector2(-12, 2),
		"weapon_anchor": Vector2(12, -18)
	},
	"zombie": {
		"default_texture_path": "res://assets/textures/characters/generated/zombie.png",
		"directional_prefix": "zombie",
		"draw_size": Vector2(52, 68),
		"body_draw_height": 60.0,
		"anchor_offset": Vector2(-26, -57),
		"shadow_size": Vector2(24, 8),
		"shadow_offset": Vector2(-12, 2)
	},
	"skeleton": {
		"default_texture_path": "res://assets/textures/characters/generated/skeleton.png",
		"directional_prefix": "skeleton",
		"draw_size": Vector2(50, 68),
		"body_draw_height": 60.0,
		"anchor_offset": Vector2(-25, -57),
		"shadow_size": Vector2(22, 7),
		"shadow_offset": Vector2(-11, 2)
	},
	"boss": {
		"default_texture_path": "res://assets/textures/characters/generated/boss_guardian.png",
		"directional_prefix": "boss",
		"draw_size": Vector2(74, 86),
		"body_draw_height": 76.0,
		"anchor_offset": Vector2(-37, -74),
		"shadow_size": Vector2(34, 10),
		"shadow_offset": Vector2(-17, 3)
	}
}


static func has_visual(visual_id: String) -> bool:
	return VISUALS.has(visual_id)


static func get_texture(visual_id: String) -> Texture2D:
	return get_state_texture(visual_id, "dr", "idle")


static func get_state_texture(visual_id: String, direction_id: String, state_id: String) -> Texture2D:
	var texture_data: Dictionary = get_state_texture_draw_data(visual_id, direction_id, state_id, Vector2.ZERO)
	return texture_data.get("texture", null)


static func get_state_texture_draw_data(visual_id: String, direction_id: String, state_id: String, base: Vector2) -> Dictionary:
	if not VISUALS.has(visual_id):
		return {}
	var entry: Dictionary = VISUALS[visual_id]
	var path: String = _resolve_texture_path(entry, direction_id, state_id)
	if path.is_empty():
		return {}
	var texture: Texture2D = _load_texture(path)
	if texture == null:
		return {}
	var analysis: Dictionary = _get_texture_analysis(path)
	var base_rect: Rect2 = get_draw_rect(visual_id, base)
	var desired_bottom: float = base_rect.position.y + base_rect.size.y
	var desired_center_x: float = base_rect.position.x + base_rect.size.x * 0.5
	var desired_body_height: float = float(entry.get("body_draw_height", base_rect.size.y - 8.0))
	var source_rect: Rect2 = analysis.get("source_rect", Rect2(Vector2.ZERO, texture.get_size()))
	var body_height: float = maxf(float(analysis.get("body_height", source_rect.size.y)), 1.0)
	var scale: float = desired_body_height / body_height
	var draw_size: Vector2 = source_rect.size * scale
	var body_center_x: float = float(analysis.get("body_center_x", source_rect.size.x * 0.5))
	var draw_position := Vector2(
		desired_center_x - body_center_x * scale,
		desired_bottom - draw_size.y
	)
	return {
		"texture": texture,
		"source_rect": source_rect,
		"draw_rect": Rect2(draw_position, draw_size)
	}


static func has_state_texture(visual_id: String, direction_id: String, state_id: String) -> bool:
	if not VISUALS.has(visual_id):
		return false
	var entry: Dictionary = VISUALS[visual_id]
	var direction_path: String = _get_directional_texture_path(entry, direction_id, state_id)
	if direction_path.is_empty():
		return false
	return FileAccess.file_exists(ProjectSettings.globalize_path(direction_path))


static func cardinal_to_visual_direction(direction: Vector2) -> String:
	if direction == Vector2.RIGHT:
		return "dr"
	if direction == Vector2.LEFT:
		return "ul"
	if direction == Vector2.UP:
		return "ur"
	if direction == Vector2.DOWN:
		return "dl"
	return "dr"


static func _get_directional_texture_path(entry: Dictionary, direction_id: String, state_id: String) -> String:
	var prefix: String = entry.get("directional_prefix", "")
	if prefix.is_empty():
		return ""
	if not DIRECTION_IDS.has(direction_id):
		direction_id = "dr"
	if not STATE_IDS.has(state_id):
		state_id = "idle"
	return "res://assets/textures/characters/directional/%s_%s_%s.png" % [prefix, state_id, direction_id]


static func _resolve_texture_path(entry: Dictionary, direction_id: String, state_id: String) -> String:
	var direction_path: String = _get_directional_texture_path(entry, direction_id, state_id)
	if not direction_path.is_empty():
		var directional_texture: Texture2D = _load_texture(direction_path)
		if directional_texture != null:
			return direction_path
	return entry.get("default_texture_path", "")


static func _load_texture(path: String) -> Texture2D:
	var absolute_path: String = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute_path):
		_texture_cache[path] = {
			"mtime": -1,
			"texture": null
		}
		return null
	var modified_time: int = FileAccess.get_modified_time(absolute_path)
	var cached_entry: Variant = _texture_cache.get(path)
	if cached_entry is Dictionary and cached_entry.get("mtime", -1) == modified_time:
		return cached_entry.get("texture", null)
	var image := Image.new()
	var error: Error = image.load(absolute_path)
	if error != OK:
		push_warning("CharacterVisuals: failed to load texture %s" % path)
		return null
	var texture := ImageTexture.create_from_image(image)
	_texture_cache[path] = {
		"mtime": modified_time,
		"texture": texture
	}
	return texture


static func _get_texture_analysis(path: String) -> Dictionary:
	var absolute_path: String = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute_path):
		return {}
	var modified_time: int = FileAccess.get_modified_time(absolute_path)
	var cached_entry: Variant = _texture_analysis_cache.get(path)
	if cached_entry is Dictionary and cached_entry.get("mtime", -1) == modified_time:
		return cached_entry
	var image := Image.new()
	var error: Error = image.load(absolute_path)
	if error != OK:
		return {}
	var used_rect: Rect2i = image.get_used_rect()
	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		used_rect = Rect2i(Vector2i.ZERO, image.get_size())
	var row_counts: Array[int] = []
	var max_row_count: int = 0
	for y in range(used_rect.position.y, used_rect.end.y):
		var row_count: int = 0
		for x in range(used_rect.position.x, used_rect.end.x):
			if image.get_pixel(x, y).a > 0.03:
				row_count += 1
		row_counts.append(row_count)
		max_row_count = max(max_row_count, row_count)
	var body_top_index: int = 0
	var body_threshold: int = max(6, int(round(max_row_count * 0.38)))
	for i in range(row_counts.size()):
		if row_counts[i] >= body_threshold:
			body_top_index = i
			break
	var body_height: int = max(used_rect.size.y - body_top_index, 1)
	var sample_start: int = body_top_index + int(round(body_height * 0.42))
	var sample_end: int = body_top_index + int(round(body_height * 0.82))
	var centers: Array[float] = []
	for y in range(max(sample_start, body_top_index), min(sample_end, used_rect.size.y)):
		var min_x: int = -1
		var max_x: int = -1
		for x in range(used_rect.position.x, used_rect.end.x):
			if image.get_pixel(x, used_rect.position.y + y).a > 0.03:
				if min_x == -1:
					min_x = x
				max_x = x
		if min_x != -1 and max_x != -1 and (max_x - min_x + 1) >= max(4, int(round(max_row_count * 0.22))):
			centers.append(((min_x + max_x) * 0.5) - used_rect.position.x)
	var body_center_x: float = used_rect.size.x * 0.5
	if not centers.is_empty():
		centers.sort()
		body_center_x = centers[centers.size() / 2]
	var analysis := {
		"mtime": modified_time,
		"source_rect": Rect2(used_rect.position, used_rect.size),
		"body_height": body_height,
		"body_center_x": body_center_x
	}
	_texture_analysis_cache[path] = analysis
	return analysis


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
