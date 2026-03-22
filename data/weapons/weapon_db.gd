extends RefCounted
class_name WeaponDB

const DAGGER := preload("res://data/weapons/dagger.tres")
const CLUB := preload("res://data/weapons/club.tres")
const WOODCUTTER_AXE := preload("res://data/weapons/woodcutter_axe.tres")
const SHORT_SWORD := preload("res://data/weapons/short_sword.tres")
const LONG_SWORD := preload("res://data/weapons/long_sword.tres")
const MAGIC_LONG_SWORD := preload("res://data/weapons/magic_long_sword.tres")

const DATA := {
	"dagger": DAGGER,
	"club": CLUB,
	"woodcutter_axe": WOODCUTTER_AXE,
	"short_sword": SHORT_SWORD,
	"long_sword": LONG_SWORD,
	"magic_long_sword": MAGIC_LONG_SWORD
}


static func get_weapon(weapon_id: String):
	return DATA.get(weapon_id, DAGGER)


static func get_default_weapon_id() -> String:
	return "dagger"


static func get_default_weapon():
	return DAGGER
