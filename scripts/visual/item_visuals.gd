extends RefCounted
class_name ItemVisuals

const ItemDB := preload("res://data/items/item_db.gd")
const WeaponDB := preload("res://data/weapons/weapon_db.gd")

static var _texture_cache: Dictionary = {}

const WEAPON_ICON_PATHS := {
	"dagger": "res://assets/textures/ui/weapons/dagger.png",
	"club": "res://assets/textures/ui/weapons/club.png",
	"woodcutter_axe": "res://assets/textures/ui/weapons/woodcutter_axe.png",
	"pickaxe": "res://assets/textures/ui/weapons/pickaxe.png",
	"short_sword": "res://assets/textures/ui/weapons/short_sword.png",
	"long_sword": "res://assets/textures/ui/weapons/long_sword.png",
	"magic_long_sword": "res://assets/textures/ui/weapons/magic_long_sword.png"
}

const AMULET_ICON_PATH := "res://assets/textures/ui/items/amulet.png"
const HEAL_DROP_ICON_PATH := "res://assets/textures/ui/items/heal_drop.png"
const GOLD_COIN_PATH := "res://output/imagegen/items/gold_coin.png"
const PORTAL_ACTIVE_PATH := "res://assets/textures/ui/portal/exit_active.png"
const PORTAL_INACTIVE_PATH := "res://assets/textures/ui/portal/exit_inactive.png"
const CROSSHAIR_PATH := "res://assets/textures/ui/crosshair.png"
const HEALTH_BAR_UNDER_PATH := "res://assets/textures/ui/health_bar_under.png"
const HEALTH_BAR_FILL_PATH := "res://assets/textures/ui/health_bar_fill.png"


static func get_weapon_icon(weapon_id: String) -> Texture2D:
	var weapon_data = WeaponDB.get_weapon(weapon_id)
	if weapon_data != null and weapon_data.icon != null:
		return weapon_data.icon
	var resolved_id: String = weapon_id if WEAPON_ICON_PATHS.has(weapon_id) else WeaponDB.get_default_weapon_id()
	return _load_texture(WEAPON_ICON_PATHS.get(resolved_id, ""))


static func get_reward_icon(reward_data: Dictionary) -> Texture2D:
	var item_data = ItemDB.get_item_from_reward(reward_data)
	if item_data != null and item_data.icon != null:
		return item_data.icon
	var reward_type: String = reward_data.get("type", "")
	if reward_type == "weapon":
		return get_weapon_icon(reward_data.get("id", WeaponDB.get_default_weapon_id()))
	if reward_type == "heal":
		return _load_texture(HEAL_DROP_ICON_PATH)
	if reward_type == "gold":
		return _load_texture(GOLD_COIN_PATH)
	if reward_type == "amulet":
		return _load_texture(AMULET_ICON_PATH)
	return null


static func get_amulet_icon() -> Texture2D:
	var amulet_data = ItemDB.get_amulet()
	if amulet_data != null and amulet_data.icon != null:
		return amulet_data.icon
	return _load_texture(AMULET_ICON_PATH)


static func get_gold_icon() -> Texture2D:
	return _load_texture(GOLD_COIN_PATH)


static func get_portal_texture(active: bool) -> Texture2D:
	return _load_texture(PORTAL_ACTIVE_PATH if active else PORTAL_INACTIVE_PATH)


static func get_crosshair_texture() -> Texture2D:
	return _load_texture(CROSSHAIR_PATH)


static func get_health_bar_under_texture() -> Texture2D:
	return _load_texture(HEALTH_BAR_UNDER_PATH)


static func get_health_bar_fill_texture() -> Texture2D:
	return _load_texture(HEALTH_BAR_FILL_PATH)


static func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
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
		return null
	var texture := ImageTexture.create_from_image(image)
	_texture_cache[path] = {
		"mtime": modified_time,
		"texture": texture
	}
	return texture
