extends RefCounted
class_name CharacterVisuals

const IsoMapper := preload("res://scripts/core/iso.gd")
static var _texture_cache: Dictionary = {}
static var _texture_analysis_cache: Dictionary = {}
static var _fallback_warning_cache: Dictionary = {}
const DIRECTION_IDS := ["up", "down", "left", "right", "up_left", "up_right", "down_left", "down_right"]
const LEGACY_DIRECTION_IDS := ["dr", "ul", "ur", "dl"]
const STATE_IDS := ["idle", "walk", "attack", "hit", "death"]
const DIRECTION_VECTORS := {
	"up": Vector2.UP,
	"down": Vector2.DOWN,
	"left": Vector2.LEFT,
	"right": Vector2.RIGHT,
	"up_left": Vector2(-1.0, -1.0),
	"up_right": Vector2(1.0, -1.0),
	"down_left": Vector2(-1.0, 1.0),
	"down_right": Vector2(1.0, 1.0)
}

const VISUALS := {
	"player": {
		"default_texture_path": "res://assets/textures/characters/generated/player_warrior.png",
		"directional_prefix": "player",
		"state_direction_overrides": {
			"attack": {
				"left": "right",
				"right": "left"
			}
		},
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
	return not _get_valid_directional_texture_path(entry, direction_id, state_id, frame_id).is_empty()


static func get_direction_name(dir: Vector2) -> String:
	if dir.length() < 0.1:
		return "down"

	var angle = atan2(dir.y, dir.x)
	var deg = rad_to_deg(angle)

	if deg < 0.0:
		deg += 360.0

	if deg >= 337.5 or deg < 22.5:
		return "right"
	elif deg < 67.5:
		return "down_right"
	elif deg < 112.5:
		return "down"
	elif deg < 157.5:
		return "down_left"
	elif deg < 202.5:
		return "left"
	elif deg < 247.5:
		return "up_left"
	elif deg < 292.5:
		return "up"
	else:
		return "up_right"


static func vector_to_visual_direction(direction: Vector2) -> String:
	return get_direction_name(direction)


static func logic_vector_to_visual_direction(direction: Vector2) -> String:
	return get_direction_name(IsoMapper.logic_direction_to_screen(direction))


static func cardinal_to_visual_direction(direction: Vector2) -> String:
	return get_direction_name(direction)


static func get_logic_direction_name_for_visual(visual_id: String, direction: Vector2, state_id: String) -> String:
	return get_best_direction_name_for_visual(visual_id, IsoMapper.logic_direction_to_screen(direction), state_id)


static func get_screen_direction_name_for_visual(visual_id: String, direction: Vector2, state_id: String) -> String:
	return get_best_direction_name_for_visual(visual_id, direction, state_id)


static func get_best_direction_name_for_visual(visual_id: String, screen_direction: Vector2, state_id: String) -> String:
	var requested_direction_id: String = get_direction_name(screen_direction)
	if not VISUALS.has(visual_id):
		return requested_direction_id
	if _has_direction_animation(visual_id, requested_direction_id, state_id):
		return requested_direction_id

	var best_direction_id: String = _find_best_available_direction_id(visual_id, screen_direction, state_id)
	if not best_direction_id.is_empty():
		return best_direction_id

	if state_id != "idle":
		best_direction_id = _find_best_available_direction_id(visual_id, screen_direction, "idle")
		if not best_direction_id.is_empty():
			return best_direction_id

	return requested_direction_id


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


static func get_animation_names(visual_id: String) -> PackedStringArray:
	var names: PackedStringArray = []
	if not VISUALS.has(visual_id):
		return names
	for state_id in STATE_IDS:
		for direction_id in DIRECTION_IDS:
			names.append(get_animation_name(state_id, direction_id))
	return names


static func _has_direction_animation(visual_id: String, direction_id: String, state_id: String) -> bool:
	if state_id == "walk":
		return has_animation_frames(visual_id, direction_id, state_id)
	return has_state_texture(visual_id, direction_id, state_id)


static func _find_best_available_direction_id(visual_id: String, screen_direction: Vector2, state_id: String) -> String:
	var target_direction: Vector2 = screen_direction.normalized() if screen_direction.length_squared() > 0.001 else Vector2.DOWN
	var best_direction_id: String = ""
	var best_score: float = -2.0

	for candidate_direction_id in DIRECTION_IDS:
		if not _has_direction_animation(visual_id, candidate_direction_id, state_id):
			continue
		var candidate_direction: Vector2 = DIRECTION_VECTORS.get(candidate_direction_id, Vector2.DOWN).normalized()
		var score: float = target_direction.dot(candidate_direction)
		if score > best_score:
			best_score = score
			best_direction_id = candidate_direction_id

	return best_direction_id


static func _get_directional_texture_path(entry: Dictionary, direction_id: String, state_id: String, frame_id: String = "") -> String:
	var prefix: String = entry.get("directional_prefix", "")
	if prefix.is_empty():
		return ""
	if not DIRECTION_IDS.has(direction_id):
		return ""
	if not STATE_IDS.has(state_id):
		return ""
	var resolved_direction_id: String = _resolve_state_direction_id(entry, direction_id, state_id)
	return "res://assets/textures/characters/extended/%s_%s.png" % [prefix, get_animation_frame_name(state_id, resolved_direction_id, frame_id)]


static func _resolve_texture_path(entry: Dictionary, direction_id: String, state_id: String, frame_id: String = "") -> String:
	var requested_animation: String = get_animation_frame_name(state_id, direction_id, frame_id)
	var direction_path: String = _get_valid_directional_texture_path(entry, direction_id, state_id, frame_id)
	if not direction_path.is_empty():
		return direction_path

	for fallback_direction_id in _get_direction_fallback_candidates(direction_id):
		var fallback_path: String = _get_valid_directional_texture_path(entry, fallback_direction_id, state_id, frame_id)
		if not fallback_path.is_empty():
			_warn_missing_texture(requested_animation, fallback_path)
			return fallback_path

	if state_id != "idle":
		var idle_same_direction_path: String = _get_valid_directional_texture_path(entry, direction_id, "idle")
		if not idle_same_direction_path.is_empty():
			_warn_missing_texture(requested_animation, idle_same_direction_path)
			return idle_same_direction_path

		for fallback_direction_id in _get_direction_fallback_candidates(direction_id):
			var idle_fallback_path: String = _get_valid_directional_texture_path(entry, fallback_direction_id, "idle")
			if not idle_fallback_path.is_empty():
				_warn_missing_texture(requested_animation, idle_fallback_path)
				return idle_fallback_path

	_warn_missing_texture(requested_animation, entry.get("default_texture_path", ""))
	return entry.get("default_texture_path", "")


static func _get_valid_directional_texture_path(entry: Dictionary, direction_id: String, state_id: String, frame_id: String = "") -> String:
	var direction_path: String = _get_directional_texture_path(entry, direction_id, state_id, frame_id)
	if direction_path.is_empty():
		return ""
	if _load_texture(direction_path) == null:
		return ""
	var analysis: Dictionary = _get_texture_analysis(direction_path)
	if not _is_texture_analysis_usable(analysis):
		return ""
	return direction_path


static func _get_direction_fallback_candidates(direction_id: String) -> Array[String]:
	match direction_id:
		"up":
			return ["up_left", "up_right", "left", "right", "down"]
		"down":
			return ["down_left", "down_right", "left", "right", "up"]
		"left":
			return ["up_left", "down_left", "up", "down", "right"]
		"right":
			return ["up_right", "down_right", "up", "down", "left"]
		"up_left":
			return ["up", "left", "up_right", "down_left", "down_right"]
		"up_right":
			return ["up", "right", "up_left", "down_right", "down_left"]
		"down_left":
			return ["down", "left", "up_left", "down_right", "up_right"]
		"down_right":
			return ["down", "right", "up_right", "down_left", "up_left"]
		_:
			return ["down"]


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


static func _resolve_state_direction_id(entry: Dictionary, direction_id: String, state_id: String) -> String:
	var state_overrides: Dictionary = entry.get("state_direction_overrides", {})
	if state_overrides.is_empty():
		return direction_id
	var direction_overrides: Dictionary = state_overrides.get(state_id, {})
	if direction_overrides.is_empty():
		return direction_id
	return String(direction_overrides.get(direction_id, direction_id))


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
	var has_visible_pixels: bool = used_rect.size.x > 0 and used_rect.size.y > 0
	if not has_visible_pixels:
		used_rect = Rect2i(Vector2i.ZERO, image.get_size())
	var image_size: Vector2i = image.get_size()
	var opaque_corner_count: int = 0
	var corner_samples := [
		Vector2i(0, 0),
		Vector2i(max(image_size.x - 1, 0), 0),
		Vector2i(0, max(image_size.y - 1, 0)),
		Vector2i(max(image_size.x - 1, 0), max(image_size.y - 1, 0))
	]
	for sample in corner_samples:
		if image.get_pixelv(sample).a > 0.03:
			opaque_corner_count += 1
	var touching_edge_count: int = 0
	if used_rect.position.x <= 1:
		touching_edge_count += 1
	if used_rect.position.y <= 1:
		touching_edge_count += 1
	if used_rect.end.x >= image_size.x - 1:
		touching_edge_count += 1
	if used_rect.end.y >= image_size.y - 1:
		touching_edge_count += 1
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
		"image_size": image_size,
		"has_visible_pixels": has_visible_pixels,
		"opaque_corner_count": opaque_corner_count,
		"touching_edge_count": touching_edge_count,
		"source_rect": Rect2(used_rect.position, used_rect.size),
		"body_height": body_height,
		"body_center_x": body_center_x
	}
	_texture_analysis_cache[path] = analysis
	return analysis


static func _is_texture_analysis_usable(analysis: Dictionary) -> bool:
	if analysis.is_empty():
		return false
	if not analysis.get("has_visible_pixels", true):
		return false

	var source_rect: Rect2 = analysis.get("source_rect", Rect2())
	var image_size: Vector2i = analysis.get("image_size", Vector2i.ZERO)
	var fills_entire_canvas: bool = source_rect.position.is_zero_approx() and int(source_rect.size.x) == image_size.x and int(source_rect.size.y) == image_size.y
	var image_area: float = maxf(float(image_size.x * image_size.y), 1.0)
	var source_area_ratio: float = (source_rect.size.x * source_rect.size.y) / image_area
	if fills_entire_canvas and int(analysis.get("opaque_corner_count", 0)) >= 3:
		return false
	if int(analysis.get("touching_edge_count", 0)) >= 2:
		return false
	if int(analysis.get("touching_edge_count", 0)) >= 1 and source_area_ratio >= 0.8:
		return false
	return true


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
