extends RefCounted
class_name PrototypeLevelData


static func get_levels() -> Array[Dictionary]:
	return [
		_village_level(),
		_forest_level(),
		_cave_level(),
		_prison_level(),
		_temple_level(),
		_abyss_level()
	]


static func _border_rects() -> Array:
	return [
		Rect2i(0, 0, 32, 1),
		Rect2i(0, 31, 32, 1),
		Rect2i(0, 0, 1, 32),
		Rect2i(31, 0, 1, 32)
	]


static func _material(tile_name: String, rects: Array) -> Dictionary:
	return {"tile": tile_name, "rects": rects}


static func _village_level() -> Dictionary:
	var house_north_left: Array = [
		Rect2i(4, 4, 6, 1),
		Rect2i(4, 5, 1, 4),
		Rect2i(9, 5, 1, 4),
		Rect2i(4, 9, 2, 1),
		Rect2i(8, 9, 2, 1)
	]
	var house_north_right: Array = [
		Rect2i(20, 5, 6, 1),
		Rect2i(20, 6, 1, 4),
		Rect2i(25, 6, 1, 4),
		Rect2i(20, 10, 2, 1),
		Rect2i(24, 10, 2, 1)
	]
	var shrine_square: Array = [
		Rect2i(13, 13, 4, 1),
		Rect2i(13, 14, 1, 3),
		Rect2i(16, 14, 1, 3),
		Rect2i(13, 17, 1, 1),
		Rect2i(16, 17, 1, 1)
	]
	var barn: Array = [
		Rect2i(22, 20, 5, 1),
		Rect2i(22, 21, 1, 4),
		Rect2i(26, 21, 1, 4),
		Rect2i(22, 25, 2, 1),
		Rect2i(25, 25, 2, 1)
	]
	var shed: Array = [
		Rect2i(6, 20, 4, 1),
		Rect2i(6, 21, 1, 3),
		Rect2i(9, 21, 1, 3),
		Rect2i(6, 24, 1, 1),
		Rect2i(9, 24, 1, 1)
	]
	var fences: Array = [
		Rect2i(11, 23, 4, 1),
		Rect2i(11, 24, 1, 2),
		Rect2i(14, 24, 1, 2),
		Rect2i(11, 26, 4, 1),
		Rect2i(18, 22, 3, 1),
		Rect2i(18, 23, 1, 2),
		Rect2i(20, 23, 1, 2),
		Rect2i(18, 25, 3, 1),
		Rect2i(5, 14, 1, 4),
		Rect2i(6, 17, 4, 1)
	]
	var well_and_crates: Array = [
		Rect2i(14, 15, 2, 2),
		Rect2i(24, 18, 1, 1),
		Rect2i(8, 13, 1, 1)
	]
	var paths: Array = [
		Rect2i(2, 26, 8, 3),
		Rect2i(8, 24, 5, 3),
		Rect2i(12, 21, 5, 3),
		Rect2i(16, 18, 6, 3),
		Rect2i(20, 15, 5, 3),
		Rect2i(23, 10, 4, 6),
		Rect2i(24, 4, 5, 6),
		Rect2i(6, 14, 7, 3)
	]
	var walls: Array = _border_rects() + house_north_left + house_north_right + shrine_square + barn + shed
	return {
		"id": "village",
		"name": "Das Dorf",
		"next_level_id": "forest",
		"theme": "village",
		"size": Vector2i(32, 32),
		"start": Vector2i(3, 27),
		"exit": Vector2i(28, 4),
		"chest": {
			"position": Vector2i(7, 15),
			"reward": {"type": "weapon", "id": "club", "label": "Knueppel"}
		},
		"amulet": {
			"position": Vector2i(23, 13),
			"label": "Dorfsiegel erhalten"
		},
		"accent_rects": paths,
		"wall_rects": walls,
		"height_one_rects": fences + well_and_crates,
		"height_two_rects": walls,
		"material_rects": [
			_material("wood", barn + shed + fences)
		],
		"enemies": [
			{"type": "zombie", "position": Vector2i(15, 22), "patrol": [Vector2i(15, 22), Vector2i(18, 20), Vector2i(20, 18), Vector2i(17, 21)]},
			{"type": "zombie", "position": Vector2i(10, 16)},
			{"type": "zombie", "position": Vector2i(20, 18)},
			{"type": "zombie", "position": Vector2i(23, 14)},
			{"type": "skeleton", "position": Vector2i(25, 12)},
			{"type": "snake", "position": Vector2i(22, 13)}
		]
	}


static func _forest_level() -> Dictionary:
	var trees_north_west: Array = [
		Rect2i(4, 6, 2, 2),
		Rect2i(6, 5, 1, 2),
		Rect2i(7, 7, 2, 2),
		Rect2i(5, 8, 1, 1)
	]
	var trees_north_mid: Array = [
		Rect2i(11, 4, 2, 3),
		Rect2i(13, 5, 1, 2),
		Rect2i(14, 7, 2, 1)
	]
	var trees_north_east: Array = [
		Rect2i(21, 4, 2, 2),
		Rect2i(23, 5, 1, 3),
		Rect2i(24, 7, 2, 2),
		Rect2i(22, 8, 1, 1)
	]
	var trees_mid_left: Array = [
		Rect2i(5, 14, 2, 2),
		Rect2i(7, 13, 1, 2),
		Rect2i(8, 15, 2, 2),
		Rect2i(6, 17, 1, 1)
	]
	var trees_center: Array = [
		Rect2i(14, 12, 2, 2),
		Rect2i(16, 11, 1, 2),
		Rect2i(17, 13, 2, 2),
		Rect2i(15, 15, 1, 1)
	]
	var trees_mid_right: Array = [
		Rect2i(22, 14, 2, 2),
		Rect2i(24, 13, 1, 3),
		Rect2i(25, 16, 2, 2),
		Rect2i(23, 17, 1, 1)
	]
	var trees_south_west: Array = [
		Rect2i(4, 22, 2, 2),
		Rect2i(6, 21, 1, 3),
		Rect2i(7, 24, 2, 2),
		Rect2i(5, 25, 1, 1),
		Rect2i(9, 23, 1, 1)
	]
	var trees_south_mid: Array = [
		Rect2i(13, 22, 2, 2),
		Rect2i(15, 21, 1, 2),
		Rect2i(16, 23, 2, 2),
		Rect2i(14, 25, 1, 1)
	]
	var ruins: Array = [
		Rect2i(24, 23, 2, 1),
		Rect2i(23, 24, 1, 2),
		Rect2i(26, 24, 1, 1)
	]
	var shrubs: Array = [
		Rect2i(10, 11, 1, 1),
		Rect2i(12, 18, 1, 2),
		Rect2i(20, 12, 1, 1),
		Rect2i(21, 21, 2, 1),
		Rect2i(26, 8, 1, 1),
		Rect2i(7, 27, 1, 1)
	]
	var trails: Array = [
		Rect2i(2, 27, 6, 3),
		Rect2i(7, 24, 4, 4),
		Rect2i(10, 20, 4, 5),
		Rect2i(13, 17, 4, 4),
		Rect2i(16, 13, 5, 4),
		Rect2i(20, 9, 4, 4),
		Rect2i(23, 6, 5, 4),
		Rect2i(23, 22, 5, 4)
	]
	var tree_walls: Array = _border_rects() + trees_north_west + trees_north_mid + trees_north_east + trees_mid_left + trees_center + trees_mid_right + trees_south_west + trees_south_mid
	return {
		"id": "forest",
		"name": "Der Wald",
		"next_level_id": "cave",
		"theme": "forest",
		"size": Vector2i(32, 32),
		"start": Vector2i(3, 28),
		"exit": Vector2i(28, 3),
		"chest": {
			"position": Vector2i(25, 24),
			"reward": {"type": "weapon", "id": "woodcutter_axe", "label": "Holzaxt"}
		},
		"amulet": {
			"position": Vector2i(23, 23),
			"label": "Waldamulett erhalten"
		},
		"accent_rects": trails,
		"wall_rects": tree_walls,
		"height_one_rects": shrubs,
		"height_two_rects": tree_walls,
		"material_rects": [
			_material("dark_stone", ruins)
		],
		"enemies": [
			{"type": "zombie", "position": Vector2i(10, 25)},
			{"type": "zombie", "position": Vector2i(12, 22)},
			{"type": "zombie", "position": Vector2i(17, 19)},
			{"type": "skeleton", "position": Vector2i(20, 17), "patrol": [Vector2i(20, 17), Vector2i(22, 15), Vector2i(25, 18), Vector2i(22, 20)]},
			{"type": "zombie", "position": Vector2i(22, 12)},
			{"type": "skeleton", "position": Vector2i(24, 10)},
			{"type": "zombie", "position": Vector2i(24, 22), "drop": {"type": "heal", "amount": 2, "label": "Verband"}},
			{"type": "skeleton", "position": Vector2i(26, 21)},
			{"type": "snake", "position": Vector2i(24, 23)}
		]
	}


static func _cave_level() -> Dictionary:
	var north_ridge_left: Array = [
		Rect2i(4, 5, 6, 2),
		Rect2i(4, 7, 2, 4),
		Rect2i(8, 8, 2, 2)
	]
	var north_ridge_mid: Array = [
		Rect2i(12, 4, 5, 2),
		Rect2i(15, 6, 2, 3),
		Rect2i(11, 8, 2, 3)
	]
	var north_ridge_right: Array = [
		Rect2i(20, 5, 6, 2),
		Rect2i(23, 7, 2, 4),
		Rect2i(21, 10, 3, 2)
	]
	var west_chamber: Array = [
		Rect2i(6, 14, 3, 2),
		Rect2i(5, 16, 2, 4),
		Rect2i(8, 18, 2, 2)
	]
	var center_chamber: Array = [
		Rect2i(13, 13, 3, 2),
		Rect2i(16, 12, 2, 3),
		Rect2i(17, 15, 2, 4),
		Rect2i(14, 18, 3, 2)
	]
	var east_chamber: Array = [
		Rect2i(23, 14, 3, 2),
		Rect2i(24, 16, 2, 4),
		Rect2i(22, 19, 3, 2)
	]
	var south_chamber: Array = [
		Rect2i(10, 24, 4, 2),
		Rect2i(16, 23, 3, 2),
		Rect2i(21, 23, 1, 3),
		Rect2i(25, 23, 1, 3),
		Rect2i(22, 26, 3, 1)
	]
	var outcroppings: Array = [
		Rect2i(10, 14, 1, 1),
		Rect2i(19, 10, 1, 2),
		Rect2i(12, 21, 2, 1),
		Rect2i(22, 22, 1, 1),
		Rect2i(7, 11, 1, 1)
	]
	var cave_path: Array = [
		Rect2i(2, 27, 7, 2),
		Rect2i(8, 24, 4, 3),
		Rect2i(11, 20, 5, 3),
		Rect2i(15, 17, 4, 3),
		Rect2i(18, 13, 4, 3),
		Rect2i(21, 9, 4, 3),
		Rect2i(24, 5, 5, 3),
		Rect2i(22, 23, 5, 3)
	]
	var cave_walls: Array = _border_rects() + north_ridge_left + north_ridge_mid + north_ridge_right + west_chamber + center_chamber + east_chamber + south_chamber
	return {
		"id": "cave",
		"name": "Die Hoehle",
		"next_level_id": "prison",
		"theme": "cave",
		"size": Vector2i(32, 32),
		"start": Vector2i(3, 28),
		"exit": Vector2i(28, 4),
		"chest": {
			"position": Vector2i(24, 24),
			"reward": {"type": "weapon", "id": "pickaxe", "label": "Spitzhacke"}
		},
		"amulet": {
			"position": Vector2i(22, 24),
			"label": "Hoehlenamulett erhalten"
		},
		"accent_rects": cave_path,
		"wall_rects": cave_walls,
		"height_one_rects": outcroppings,
		"height_two_rects": cave_walls,
		"material_rects": [],
		"enemies": [
			{"type": "zombie", "position": Vector2i(9, 26)},
			{"type": "zombie", "position": Vector2i(14, 21)},
			{"type": "skeleton", "position": Vector2i(16, 17), "patrol": [Vector2i(16, 17), Vector2i(18, 15), Vector2i(21, 13), Vector2i(18, 16)]},
			{"type": "zombie", "position": Vector2i(19, 16)},
			{"type": "zombie", "position": Vector2i(21, 14)},
			{"type": "skeleton", "position": Vector2i(25, 10), "drop": {"type": "heal", "amount": 2, "label": "Bandage"}},
			{"type": "zombie", "position": Vector2i(23, 24)},
			{"type": "snake", "position": Vector2i(21, 24)}
		]
	}


static func _prison_level() -> Dictionary:
	var left_cell_top: Array = [
		Rect2i(5, 6, 1, 5),
		Rect2i(5, 6, 4, 1),
		Rect2i(5, 10, 4, 1),
		Rect2i(8, 7, 1, 1),
		Rect2i(8, 9, 1, 1)
	]
	var left_cell_mid: Array = [
		Rect2i(5, 13, 1, 5),
		Rect2i(5, 13, 4, 1),
		Rect2i(5, 17, 4, 1),
		Rect2i(8, 14, 1, 1),
		Rect2i(8, 16, 1, 1)
	]
	var left_cell_low: Array = [
		Rect2i(5, 20, 1, 6),
		Rect2i(5, 20, 4, 1),
		Rect2i(5, 25, 4, 1),
		Rect2i(8, 21, 1, 2),
		Rect2i(8, 24, 1, 1)
	]
	var right_cell_top: Array = [
		Rect2i(23, 6, 1, 5),
		Rect2i(20, 6, 4, 1),
		Rect2i(20, 10, 4, 1),
		Rect2i(20, 7, 1, 1),
		Rect2i(20, 9, 1, 1)
	]
	var right_cell_mid: Array = [
		Rect2i(23, 13, 1, 5),
		Rect2i(20, 13, 4, 1),
		Rect2i(20, 17, 4, 1),
		Rect2i(20, 14, 1, 1),
		Rect2i(20, 16, 1, 1)
	]
	var right_cell_low: Array = [
		Rect2i(23, 20, 1, 6),
		Rect2i(20, 20, 4, 1),
		Rect2i(20, 25, 4, 1),
		Rect2i(20, 21, 1, 2),
		Rect2i(20, 24, 1, 1)
	]
	var partitions: Array = [
		Rect2i(12, 5, 1, 22),
		Rect2i(15, 8, 3, 1),
		Rect2i(15, 14, 3, 1),
		Rect2i(15, 20, 3, 1),
		Rect2i(18, 8, 1, 15)
	]
	var bunks_and_crates: Array = [
		Rect2i(6, 8, 1, 1),
		Rect2i(6, 15, 1, 1),
		Rect2i(6, 22, 1, 1),
		Rect2i(21, 8, 1, 1),
		Rect2i(21, 15, 1, 1),
		Rect2i(25, 23, 1, 1)
	]
	var corridors: Array = [
		Rect2i(2, 26, 11, 3),
		Rect2i(12, 6, 3, 23),
		Rect2i(14, 6, 14, 3),
		Rect2i(24, 9, 4, 17)
	]
	var prison_walls: Array = _border_rects() + left_cell_top + left_cell_mid + left_cell_low + right_cell_top + right_cell_mid + right_cell_low + partitions
	return {
		"id": "prison",
		"name": "Das Gefaengnis",
		"next_level_id": "temple",
		"theme": "prison",
		"size": Vector2i(32, 32),
		"start": Vector2i(3, 28),
		"exit": Vector2i(28, 4),
		"chest": {
			"position": Vector2i(26, 24),
			"reward": {"type": "weapon", "id": "short_sword", "label": "Kurzschwert"}
		},
		"amulet": {
			"position": Vector2i(24, 23),
			"label": "Kerkeramulett erhalten"
		},
		"accent_rects": corridors,
		"wall_rects": prison_walls,
		"height_one_rects": bunks_and_crates,
		"height_two_rects": prison_walls,
		"material_rects": [
			_material("wood", bunks_and_crates)
		],
		"enemies": [
			{"type": "zombie", "position": Vector2i(10, 24)},
			{"type": "skeleton", "position": Vector2i(11, 22)},
			{"type": "zombie", "position": Vector2i(13, 18)},
			{"type": "skeleton", "position": Vector2i(13, 12)},
			{"type": "zombie", "position": Vector2i(16, 11)},
			{"type": "zombie", "position": Vector2i(16, 22)},
			{"type": "zombie", "position": Vector2i(25, 11)},
			{"type": "skeleton", "position": Vector2i(24, 18), "patrol": [Vector2i(24, 18), Vector2i(24, 14), Vector2i(25, 11), Vector2i(27, 14)]},
			{"type": "skeleton", "position": Vector2i(27, 22), "drop": {"type": "heal", "amount": 2, "label": "Bandage"}},
			{"type": "snake", "position": Vector2i(24, 22)}
		]
	}


static func _temple_level() -> Dictionary:
	var north_west_mass: Array = [
		Rect2i(4, 5, 3, 3),
		Rect2i(7, 6, 1, 2)
	]
	var north_east_mass: Array = [
		Rect2i(25, 5, 3, 3),
		Rect2i(24, 6, 1, 2)
	]
	var south_west_mass: Array = [
		Rect2i(4, 24, 3, 3),
		Rect2i(7, 24, 1, 2)
	]
	var side_buttresses: Array = [
		Rect2i(6, 15, 3, 2),
		Rect2i(23, 15, 3, 2)
	]
	var altar_wall: Array = [
		Rect2i(12, 6, 2, 1),
		Rect2i(18, 6, 2, 1),
		Rect2i(14, 5, 4, 1)
	]
	var pillars: Array = [
		Rect2i(10, 10, 1, 1),
		Rect2i(15, 10, 1, 1),
		Rect2i(20, 10, 1, 1),
		Rect2i(10, 19, 1, 1),
		Rect2i(15, 19, 1, 1),
		Rect2i(20, 19, 1, 1)
	]
	var altar_steps: Array = [
		Rect2i(13, 7, 6, 1),
		Rect2i(14, 6, 4, 1),
		Rect2i(24, 25, 1, 2),
		Rect2i(27, 25, 1, 2)
	]
	var side_plinths: Array = [
		Rect2i(8, 14, 1, 1),
		Rect2i(23, 14, 1, 1),
		Rect2i(24, 27, 2, 1)
	]
	var processional_paths: Array = [
		Rect2i(13, 4, 6, 25),
		Rect2i(7, 14, 18, 4),
		Rect2i(11, 6, 10, 3),
		Rect2i(23, 24, 5, 4)
	]
	var temple_walls: Array = _border_rects() + north_west_mass + north_east_mass + south_west_mass + side_buttresses + altar_wall + pillars
	return {
		"id": "temple",
		"name": "Der Tempel",
		"next_level_id": "abyss",
		"theme": "temple",
		"size": Vector2i(32, 32),
		"start": Vector2i(15, 28),
		"exit": Vector2i(15, 3),
		"chest": {
			"position": Vector2i(25, 26),
			"reward": {"type": "weapon", "id": "long_sword", "label": "Langschwert"}
		},
		"amulet": {
			"position": Vector2i(22, 25),
			"label": "Tempelamulett erhalten"
		},
		"accent_rects": processional_paths,
		"wall_rects": temple_walls,
		"height_one_rects": altar_steps + side_plinths,
		"height_two_rects": temple_walls,
		"material_rects": [
			_material("light_stone", pillars + altar_wall + altar_steps)
		],
		"enemies": [
			{"type": "zombie", "position": Vector2i(8, 18)},
			{"type": "skeleton", "position": Vector2i(11, 17)},
			{"type": "zombie", "position": Vector2i(12, 15)},
			{"type": "zombie", "position": Vector2i(19, 15)},
			{"type": "skeleton", "position": Vector2i(20, 17), "patrol": [Vector2i(20, 17), Vector2i(20, 11), Vector2i(23, 9), Vector2i(23, 17)]},
			{"type": "zombie", "position": Vector2i(23, 18)},
			{"type": "skeleton", "position": Vector2i(8, 9)},
			{"type": "skeleton", "position": Vector2i(23, 9)},
			{"type": "skeleton", "position": Vector2i(21, 24), "drop": {"type": "heal", "amount": 2, "label": "Bandage"}},
			{"type": "snake", "position": Vector2i(23, 25)}
		]
	}


static func _abyss_level() -> Dictionary:
	var south_left_cliffs: Array = [
		Rect2i(2, 21, 4, 1),
		Rect2i(2, 19, 2, 2),
		Rect2i(6, 20, 3, 2),
		Rect2i(9, 18, 3, 1),
		Rect2i(11, 16, 2, 2)
	]
	var south_right_cliffs: Array = [
		Rect2i(20, 18, 4, 1),
		Rect2i(24, 19, 3, 2),
		Rect2i(27, 21, 2, 2),
		Rect2i(22, 16, 2, 2)
	]
	var north_cliffs: Array = [
		Rect2i(5, 4, 3, 3),
		Rect2i(9, 6, 2, 2),
		Rect2i(22, 5, 4, 2),
		Rect2i(25, 8, 2, 2),
		Rect2i(13, 7, 1, 2),
		Rect2i(18, 7, 2, 1)
	]
	var arena_rim: Array = [
		Rect2i(11, 11, 2, 1),
		Rect2i(19, 11, 2, 1),
		Rect2i(9, 13, 1, 3),
		Rect2i(22, 13, 1, 3)
	]
	var low_rocks: Array = [
		Rect2i(7, 24, 1, 1),
		Rect2i(10, 22, 2, 1),
		Rect2i(22, 23, 1, 1),
		Rect2i(18, 14, 1, 1),
		Rect2i(15, 21, 2, 1)
	]
	var lava_fields: Array = [
		Rect2i(12, 23, 3, 5),
		Rect2i(16, 24, 3, 4),
		Rect2i(12, 18, 4, 2),
		Rect2i(17, 16, 4, 2),
		Rect2i(6, 7, 4, 2),
		Rect2i(11, 6, 5, 2),
		Rect2i(18, 7, 4, 2),
		Rect2i(4, 14, 2, 6),
		Rect2i(26, 14, 2, 6)
	]
	var abyss_walls: Array = _border_rects() + south_left_cliffs + south_right_cliffs + north_cliffs + arena_rim
	return {
		"id": "abyss",
		"name": "Die Abyss",
		"theme": "abyss",
		"size": Vector2i(32, 32),
		"start": Vector2i(15, 28),
		"exit": Vector2i(15, 5),
		"chest": {
			"position": Vector2i(6, 25),
			"reward": {
				"type": "weapon",
				"id": "magic_long_sword",
				"label": "Magisches Langschwert",
				"heal_amount": 6
			}
		},
		"amulet": {
			"position": Vector2i(15, 12),
			"label": "Abyss-Amulett erhalten"
		},
		"accent_rects": lava_fields,
		"wall_rects": abyss_walls,
		"height_one_rects": low_rocks,
		"height_two_rects": abyss_walls,
		"material_rects": [],
		"enemies": [
			{"type": "zombie", "position": Vector2i(9, 24)},
			{"type": "zombie", "position": Vector2i(12, 22)},
			{"type": "skeleton", "position": Vector2i(18, 21), "patrol": [Vector2i(18, 21), Vector2i(17, 18), Vector2i(19, 15), Vector2i(22, 17)]},
			{"type": "zombie", "position": Vector2i(14, 17)},
			{"type": "skeleton", "position": Vector2i(19, 15), "drop": {"type": "heal", "amount": 3, "label": "Heiltrank"}},
			{"type": "snake", "position": Vector2i(16, 12)},
			{"type": "boss", "position": Vector2i(15, 10)}
		]
	}
