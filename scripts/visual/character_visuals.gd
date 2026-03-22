extends RefCounted
class_name CharacterVisuals

static var _texture_cache: Dictionary = {}
static var _texture_analysis_cache: Dictionary = {}
static var _fallback_warning_cache: Dictionary = {}
const DIRECTION_IDS := ["up", "down", "left", "right", "up_left", "up_right", "down_left", "down_right"]
const LEGACY_DIRECTION_IDS := ["dr", "ul", "ur", "dl"]
const STATE_IDS := ["idle", "walk", "attack", "hit", "death"]
const LEGACY_DIRECTION_MAP := {
	"down_right": "dr",
	"up_left": "ul",
	"up_right": "ur",
	"down_left": "dl"
}

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
	return get_state_texture(visual_id, "down_right", "idle")


static func get_state_texture(visual_id: String, direction_id: String, state_id: String, frame_id: String = "") -> Texture2D:
	var texture_data: Dictionary = get_state_texture_draw_data(visual_id, direction_id, state_id, Vector2.ZERO, frame_id)
	return texture_data.get("texture", null)


static func get_state_texture_draw_data(visual_id: String, direction_id: String, state_id: String, base: Vector2, frame_id: String = "") -> Dictionary:
	if not VISUALS.has(visual_id):
		return {}
	var entry: Dictionary = VISUALS[visual_id]
	var path: String = _resolve_texture_path(entry, direction_id, state_id, frame_id)
	if path.is_empty():
		return {}
	var texture: Texture2D = _load_texture(path)
	if texture == null:
		_warn_missing_texture(path, "")
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
	var animation_name: String = get_animation_name(state_id, direction_id)
	var animation_frame_name: String = get_animation_frame_name(state_id, direction_id, frame_id)
	var draw_position := Vector2(
		desired_center_x - body_center_x * scale,
		desired_bottom - draw_size.y
	)
	return {
		"texture": texture,
		"source_rect": source_rect,
		"draw_rect": Rect2(draw_position, draw_size),
		"animation_name": animation_name,
		"animation_frame_name": animation_frame_name,
		"direction_id": direction_id,
		"state_id": state_id
	}


static func has_state_texture(visual_id: String, direction_id: String, state_id: String, frame_id: String = "") -> bool:
	if not VISUALS.has(visual_id):
		return false
	var entry: Dictionary = VISUALS[visual_id]
	var direction_path: String = _get_directional_texture_path(entry, direction_id, state_id, frame_id)
	if direction_path.is_empty():
		return false
	return FileAccess.file_exists(ProjectSettings.globalize_path(direction_path))


static func vector_to_visual_direction(direction: Vector2) -> String:
	if direction.length_squared() <= 0.001:
		return "down"
	var dir := direction.normalized()
	var dir_name := ""

	if absf(dir.x) > absf(dir.y):
		if dir.x > 0.0:
			if dir.y > 0.0:
				dir_name = "down_right"
			elif dir.y < 0.0:
				dir_name = "up_right"
			else:
				dir_name = "right"
		else:
			if dir.y > 0.0:
				dir_name = "down_left"
			elif dir.y < 0.0:
				dir_name = "up_left"
			else:
				dir_name = "left"
	else:
		if dir.y > 0.0:
			if dir.x > 0.0:
				dir_name = "down_right"
			elif dir.x < 0.0:
				dir_name = "down_left"
			else:
				dir_name = "down"
		else:
			if dir.x > 0.0:
				dir_name = "up_right"
			elif dir.x < 0.0:
				dir_name = "up_left"
			else:
				dir_name = "up"

	return dir_name


static func logic_vector_to_visual_direction(direction: Vector2) -> String:
	return vector_to_visual_direction(direction)


static func cardinal_to_visual_direction(direction: Vector2) -> String:
	return vector_to_visual_direction(direction)


static func get_animation_name(state_id: String, direction_id: String) -> String:
	return "%s_%s" % [state_id, direction_id]


static func get_animation_frame_name(state_id: String, direction_id: String, frame_id: String = "") -> String:
	var animation_name: String = get_animation_name(state_id, direction_id)
	if frame_id.is_empty():
		return animation_name
	return "%s_%s" % [animation_name, frame_id]


static func get_animation_frame_count(visual_id: String, direction_id: String, state_id: String) -> int:
	if not VISUALS.has(visual_id):
		return 0
	if state_id == "walk":
		var frame_count: int = 0
		if has_state_texture(visual_id, direction_id, state_id, "1"):
			frame_count += 1
		if has_state_texture(visual_id, direction_id, state_id, "2"):
			frame_count += 1
		return frame_count
	return 1 if has_state_texture(visual_id, direction_id, state_id) else 0


static func has_animation_frames(visual_id: String, direction_id: String, state_id: String) -> bool:
	var frame_count: int = get_animation_frame_count(visual_id, direction_id, state_id)
	return frame_count >= 2 if state_id == "walk" else frame_count >= 1


static func _get_directional_texture_path(entry: Dictionary, direction_id: String, state_id: String, frame_id: String = "") -> String:
	var prefix: String = entry.get("directional_prefix", "")
	if prefix.is_empty():
		return ""
	if not DIRECTION_IDS.has(direction_id):
		return ""
	if not STATE_IDS.has(state_id):
		return ""
	return "res://assets/textures/characters/extended/%s_%s.png" % [prefix, get_animation_frame_name(state_id, direction_id, frame_id)]


static func _resolve_texture_path(entry: Dictionary, direction_id: String, state_id: String, frame_id: String = "") -> String:
	var direction_path: String = _get_directional_texture_path(entry, direction_id, state_id, frame_id)
	if not direction_path.is_empty():
		var directional_texture: Texture2D = _load_texture(direction_path)
		if directional_texture != null:
			return direction_path
		_warn_missing_texture(direction_path, entry.get("default_texture_path", ""))
	elif not state_id.is_empty() or not direction_id.is_empty():
		_warn_missing_texture("%s_%s" % [state_id, direction_id], entry.get("default_texture_path", ""))
	var legacy_path: String = _get_legacy_directional_texture_path(entry, direction_id, state_id)
	if not legacy_path.is_empty():
		var legacy_texture: Texture2D = _load_texture(legacy_path)
		if legacy_texture != null:
			return legacy_path
		_warn_missing_texture(legacy_path, entry.get("default_texture_path", ""))
	return entry.get("default_texture_path", "")


static func _get_legacy_directional_texture_path(entry: Dictionary, direction_id: String, state_id: String) -> String:
	var prefix: String = entry.get("directional_prefix", "")
	if prefix.is_empty():
		return ""
	if state_id != "idle" and state_id != "attack":
		return ""
	var legacy_direction_id: String = LEGACY_DIRECTION_MAP.get(direction_id, "")
	if legacy_direction_id.is_empty():
		return ""
	return "res://assets/textures/characters/directional/%s_%s_%s.png" % [prefix, state_id, legacy_direction_id]


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


static func _warn_missing_texture(path: String, fallback_path: String) -> void:
	var cache_key: String = "%s|%s" % [path, fallback_path]
	if _fallback_warning_cache.has(cache_key):
		return
	_fallback_warning_cache[cache_key] = true
	if fallback_path.is_empty():
		push_warning("CharacterVisuals: missing texture %s" % path)
		return
	push_warning("CharacterVisuals: missing texture %s, falling back to %s" % [path, fallback_path])


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
