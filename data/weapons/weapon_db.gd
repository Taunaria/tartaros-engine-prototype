extends RefCounted
class_name WeaponDB

const DATA := {
	"club": {
		"id": "club",
		"name": "Knueppel",
		"damage": 2,
		"range": 30.0,
		"hit_radius": 38.0,
		"swing_angle_degrees": 110.0,
		"cooldown": 0.45,
		"color": Color8(137, 92, 56)
	},
	"sword": {
		"id": "sword",
		"name": "Schwert",
		"damage": 3,
		"range": 38.0,
		"hit_radius": 46.0,
		"swing_angle_degrees": 90.0,
		"cooldown": 0.38,
		"color": Color8(183, 192, 203)
	},
	"axe": {
		"id": "axe",
		"name": "Axt",
		"damage": 4,
		"range": 34.0,
		"hit_radius": 42.0,
		"swing_angle_degrees": 120.0,
		"cooldown": 0.55,
		"color": Color8(169, 185, 150)
	}
}


static func get_weapon(weapon_id: String) -> Dictionary:
	return DATA.get(weapon_id, DATA["club"]).duplicate(true)


static func get_default_weapon_id() -> String:
	return "club"
