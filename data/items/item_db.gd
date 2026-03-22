extends RefCounted
class_name ItemDB

const WeaponDB := preload("res://data/weapons/weapon_db.gd")
const AMULET := preload("res://data/items/amulet.tres")


static func get_amulet():
	return AMULET


static func get_item_from_reward(reward: Dictionary):
	var reward_type: String = reward.get("type", "")
	if reward_type == "weapon":
		return WeaponDB.get_weapon(reward.get("id", WeaponDB.get_default_weapon_id()))
	if reward_type == "amulet":
		return get_amulet()
	return null
