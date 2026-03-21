extends RefCounted
class_name WeaponDB

const DATA := {
	"dagger": {
		"id": "dagger",
		"name": "Dolch",
		"damage": 1,
		"attack_range": 24.0,
		"attack_speed": 0.32,
		"attack_width": 20.0,
		"color": Color8(210, 210, 221)
	},
	"club": {
		"id": "club",
		"name": "Knueppel",
		"damage": 2,
		"attack_range": 32.0,
		"attack_speed": 0.5,
		"attack_width": 26.0,
		"color": Color8(137, 92, 56)
	},
	"woodcutter_axe": {
		"id": "woodcutter_axe",
		"name": "Holzaxt",
		"damage": 3,
		"attack_range": 34.0,
		"attack_speed": 0.56,
		"attack_width": 32.0,
		"color": Color8(169, 185, 150)
	},
	"short_sword": {
		"id": "short_sword",
		"name": "Kurzschwert",
		"damage": 3,
		"attack_range": 38.0,
		"attack_speed": 0.4,
		"attack_width": 24.0,
		"color": Color8(183, 192, 203)
	},
	"long_sword": {
		"id": "long_sword",
		"name": "Langschwert",
		"damage": 4,
		"attack_range": 44.0,
		"attack_speed": 0.36,
		"attack_width": 26.0,
		"color": Color8(198, 209, 224)
	},
	"magic_long_sword": {
		"id": "magic_long_sword",
		"name": "Magisches Langschwert",
		"damage": 5,
		"attack_range": 50.0,
		"attack_speed": 0.32,
		"attack_width": 28.0,
		"color": Color8(108, 220, 255)
	}
}


static func get_weapon(weapon_id: String) -> Dictionary:
	return DATA.get(weapon_id, DATA["dagger"]).duplicate(true)


static func get_default_weapon_id() -> String:
	return "dagger"
