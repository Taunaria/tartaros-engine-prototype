extends RefCounted
class_name CombatDebug

const DIRECTION_ARROW_TEXTURE_PATH := "res://assets/textures/ui/debug/direction_arrow.png"
const KEYCAP_TEXTURE_PATH := "res://assets/textures/ui/debug/keycap.png"

static var _texture_cache: Dictionary = {}
static var _pressed_keyboard_labels: Array[String] = []

static var enabled: bool = false
static var enemy_logic_enabled: bool = true
static var direction_overlay_enabled: bool = false
static var last_input_label: String = "-"


static func toggle() -> bool:
	enabled = not enabled
	return enabled


static func toggle_enemy_logic() -> bool:
	enemy_logic_enabled = not enemy_logic_enabled
	return enemy_logic_enabled


static func toggle_direction_overlay() -> bool:
	direction_overlay_enabled = not direction_overlay_enabled
	return direction_overlay_enabled


static func register_last_input(event: InputEvent) -> void:
	if event == null:
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.echo:
			return
		var key_label: String = _format_key_event_label(key_event)
		if not key_label.is_empty():
			if key_event.pressed:
				if not _pressed_keyboard_labels.has(key_label):
					_pressed_keyboard_labels.append(key_label)
				_refresh_keyboard_combo_label()
			else:
				_pressed_keyboard_labels.erase(key_label)


static func get_direction_arrow_texture() -> Texture2D:
	return _load_debug_texture(DIRECTION_ARROW_TEXTURE_PATH)


static func get_keycap_texture() -> Texture2D:
	return _load_debug_texture(KEYCAP_TEXTURE_PATH)


static func _refresh_keyboard_combo_label() -> void:
	if _pressed_keyboard_labels.is_empty():
		return
	var combo_label: String = _pressed_keyboard_labels[0]
	for index in range(1, _pressed_keyboard_labels.size()):
		combo_label += " + %s" % _pressed_keyboard_labels[index]
	last_input_label = combo_label


static func _format_key_event_label(key_event: InputEventKey) -> String:
	var label := _call_text_method(key_event, "as_text_keycode")
	if not label.is_empty():
		return label

	label = _call_text_method(key_event, "as_text_physical_keycode")
	if not label.is_empty():
		return label

	if key_event.keycode != KEY_NONE:
		label = OS.get_keycode_string(key_event.keycode)
		if not label.is_empty():
			return label

	if key_event.physical_keycode != KEY_NONE:
		label = OS.get_keycode_string(key_event.physical_keycode)
		if not label.is_empty():
			return label

	return "Key"


static func _format_mouse_button_label(button_index: MouseButton) -> String:
	match button_index:
		MOUSE_BUTTON_LEFT:
			return "LMB"
		MOUSE_BUTTON_RIGHT:
			return "RMB"
		MOUSE_BUTTON_MIDDLE:
			return "MMB"
		MOUSE_BUTTON_WHEEL_UP:
			return "Wheel Up"
		MOUSE_BUTTON_WHEEL_DOWN:
			return "Wheel Down"
		MOUSE_BUTTON_WHEEL_LEFT:
			return "Wheel Left"
		MOUSE_BUTTON_WHEEL_RIGHT:
			return "Wheel Right"
		_:
			return "M%d" % int(button_index)


static func _call_text_method(object: Object, method_name: String) -> String:
	if object == null or not object.has_method(method_name):
		return ""
	var text_value: Variant = object.call(method_name)
	return "" if text_value == null else str(text_value)


static func _load_debug_texture(path: String) -> Texture2D:
	var absolute_path: String = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute_path):
		return null

	var modified_time: int = FileAccess.get_modified_time(absolute_path)
	var cached_entry: Variant = _texture_cache.get(path)
	if cached_entry is Dictionary and cached_entry.get("mtime", -1) == modified_time:
		return cached_entry.get("texture", null)

	var image := Image.new()
	var error: Error = image.load(absolute_path)
	if error != OK:
		push_warning("CombatDebug: failed to load texture %s" % path)
		return null

	var texture := ImageTexture.create_from_image(image)
	_texture_cache[path] = {
		"mtime": modified_time,
		"texture": texture
	}
	return texture
