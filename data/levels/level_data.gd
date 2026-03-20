extends RefCounted
class_name PrototypeLevelData


static func get_levels() -> Array[Dictionary]:
	return [
		{
			"id": "village",
			"name": "Das Dorf",
			"theme": "village",
			"size": Vector2i(32, 32),
			"start": Vector2i(3, 27),
			"exit": Vector2i(28, 4),
			"chest": {
				"position": Vector2i(7, 15),
				"reward": {"type": "weapon", "id": "sword", "label": "Schwert"}
			},
			"accent_rects": [
				Rect2i(3, 25, 23, 3),
				Rect2i(23, 6, 4, 22),
				Rect2i(5, 13, 6, 5)
			],
			"wall_rects": [
				Rect2i(0, 0, 32, 1),
				Rect2i(0, 31, 32, 1),
				Rect2i(0, 0, 1, 32),
				Rect2i(31, 0, 1, 32),
				Rect2i(4, 4, 8, 7),
				Rect2i(18, 5, 8, 7),
				Rect2i(13, 12, 5, 3),
				Rect2i(13, 18, 5, 2),
				Rect2i(22, 20, 4, 5),
				Rect2i(6, 21, 4, 4)
			],
			"enemies": [
				{"type": "strawman", "position": Vector2i(6, 27)},
				{"type": "zombie", "position": Vector2i(14, 23)},
				{"type": "zombie", "position": Vector2i(23, 13)}
			]
		},
		{
			"id": "forest",
			"name": "Der Wald",
			"theme": "forest",
			"size": Vector2i(32, 32),
			"start": Vector2i(3, 28),
			"exit": Vector2i(28, 3),
			"chest": {
				"position": Vector2i(25, 24),
				"reward": {"type": "heal", "amount": 3, "label": "Heilration"}
			},
			"accent_rects": [
				Rect2i(2, 26, 16, 3),
				Rect2i(16, 18, 4, 11),
				Rect2i(19, 8, 10, 4),
				Rect2i(23, 12, 5, 15)
			],
			"wall_rects": [
				Rect2i(0, 0, 32, 1),
				Rect2i(0, 31, 32, 1),
				Rect2i(0, 0, 1, 32),
				Rect2i(31, 0, 1, 32),
				Rect2i(4, 5, 5, 5),
				Rect2i(12, 4, 4, 6),
				Rect2i(22, 4, 5, 5),
				Rect2i(6, 14, 4, 4),
				Rect2i(15, 13, 5, 5),
				Rect2i(22, 15, 4, 6),
				Rect2i(5, 22, 6, 4),
				Rect2i(14, 22, 4, 4)
			],
			"enemies": [
				{"type": "zombie", "position": Vector2i(11, 26)},
				{"type": "zombie", "position": Vector2i(17, 20)},
				{"type": "zombie", "position": Vector2i(23, 10)},
				{"type": "zombie", "position": Vector2i(26, 21), "drop": {"type": "weapon", "id": "sword", "label": "Schwert"}}
			]
		},
		{
			"id": "cave",
			"name": "Die Hoehle",
			"theme": "cave",
			"size": Vector2i(32, 32),
			"start": Vector2i(3, 28),
			"exit": Vector2i(28, 4),
			"chest": {
				"position": Vector2i(24, 24),
				"reward": {"type": "weapon", "id": "axe", "label": "Axt"}
			},
			"accent_rects": [
				Rect2i(2, 26, 12, 3),
				Rect2i(12, 20, 4, 9),
				Rect2i(16, 20, 11, 4),
				Rect2i(22, 8, 4, 16),
				Rect2i(24, 6, 5, 4)
			],
			"wall_rects": [
				Rect2i(0, 0, 32, 1),
				Rect2i(0, 31, 32, 1),
				Rect2i(0, 0, 1, 32),
				Rect2i(31, 0, 1, 32),
				Rect2i(4, 4, 22, 4),
				Rect2i(4, 8, 4, 16),
				Rect2i(10, 10, 10, 3),
				Rect2i(18, 13, 3, 11),
				Rect2i(23, 11, 4, 9),
				Rect2i(10, 25, 11, 3)
			],
			"enemies": [
				{"type": "zombie", "position": Vector2i(9, 27)},
				{"type": "zombie", "position": Vector2i(14, 22)},
				{"type": "zombie", "position": Vector2i(18, 18)},
				{"type": "zombie", "position": Vector2i(25, 14)},
				{"type": "skeleton", "position": Vector2i(24, 8), "drop": {"type": "weapon", "id": "axe", "label": "Axt"}}
			]
		},
		{
			"id": "prison",
			"name": "Das Gefaengnis",
			"theme": "prison",
			"size": Vector2i(32, 32),
			"start": Vector2i(3, 28),
			"exit": Vector2i(28, 4),
			"chest": {
				"position": Vector2i(26, 24),
				"reward": {"type": "heal", "amount": 4, "label": "Grosser Trank"}
			},
			"accent_rects": [
				Rect2i(2, 26, 12, 3),
				Rect2i(12, 6, 3, 23),
				Rect2i(14, 6, 14, 3),
				Rect2i(25, 9, 3, 18)
			],
			"wall_rects": [
				Rect2i(0, 0, 32, 1),
				Rect2i(0, 31, 32, 1),
				Rect2i(0, 0, 1, 32),
				Rect2i(31, 0, 1, 32),
				Rect2i(5, 5, 2, 13),
				Rect2i(5, 21, 2, 6),
				Rect2i(8, 5, 3, 5),
				Rect2i(8, 12, 3, 5),
				Rect2i(8, 19, 3, 8),
				Rect2i(15, 10, 3, 6),
				Rect2i(15, 18, 3, 7),
				Rect2i(20, 5, 3, 5),
				Rect2i(20, 12, 3, 5),
				Rect2i(20, 19, 3, 6),
				Rect2i(25, 12, 3, 3)
			],
			"enemies": [
				{"type": "zombie", "position": Vector2i(10, 25)},
				{"type": "zombie", "position": Vector2i(13, 18)},
				{"type": "zombie", "position": Vector2i(17, 8)},
				{"type": "zombie", "position": Vector2i(18, 22)},
				{"type": "zombie", "position": Vector2i(23, 8)},
				{"type": "skeleton", "position": Vector2i(24, 18)},
				{"type": "skeleton", "position": Vector2i(27, 22), "drop": {"type": "heal", "amount": 2, "label": "Bandage"}}
			]
		},
		{
			"id": "temple",
			"name": "Der Tempel",
			"theme": "temple",
			"size": Vector2i(32, 32),
			"start": Vector2i(15, 28),
			"exit": Vector2i(15, 3),
			"chest": {
				"position": Vector2i(25, 26),
				"reward": {"type": "heal", "amount": 5, "label": "Tempeltrank"}
			},
			"accent_rects": [
				Rect2i(13, 4, 6, 25),
				Rect2i(5, 10, 22, 4),
				Rect2i(7, 20, 18, 4)
			],
			"wall_rects": [
				Rect2i(0, 0, 32, 1),
				Rect2i(0, 31, 32, 1),
				Rect2i(0, 0, 1, 32),
				Rect2i(31, 0, 1, 32),
				Rect2i(4, 4, 5, 5),
				Rect2i(23, 4, 5, 5),
				Rect2i(4, 23, 5, 5),
				Rect2i(23, 23, 5, 5),
				Rect2i(10, 10, 2, 2),
				Rect2i(20, 10, 2, 2),
				Rect2i(10, 19, 2, 2),
				Rect2i(20, 19, 2, 2),
				Rect2i(6, 15, 4, 2),
				Rect2i(22, 15, 4, 2)
			],
			"enemies": [
				{"type": "zombie", "position": Vector2i(8, 18)},
				{"type": "zombie", "position": Vector2i(12, 15)},
				{"type": "zombie", "position": Vector2i(19, 15)},
				{"type": "zombie", "position": Vector2i(23, 18)},
				{"type": "skeleton", "position": Vector2i(8, 9)},
				{"type": "skeleton", "position": Vector2i(23, 9)},
				{"type": "skeleton", "position": Vector2i(11, 24)},
				{"type": "skeleton", "position": Vector2i(20, 24), "drop": {"type": "heal", "amount": 2, "label": "Bandage"}}
			]
		},
		{
			"id": "abyss",
			"name": "Die Abyss",
			"theme": "abyss",
			"size": Vector2i(32, 32),
			"start": Vector2i(15, 28),
			"exit": Vector2i(15, 5),
			"chest": {
				"position": Vector2i(6, 25),
				"reward": {"type": "heal", "amount": 10, "label": "Vollheilung"}
			},
			"accent_rects": [
				Rect2i(13, 22, 6, 8),
				Rect2i(11, 16, 10, 4),
				Rect2i(5, 5, 22, 7),
				Rect2i(3, 12, 3, 12),
				Rect2i(26, 12, 3, 12)
			],
			"wall_rects": [
				Rect2i(0, 0, 32, 1),
				Rect2i(0, 31, 32, 1),
				Rect2i(0, 0, 1, 32),
				Rect2i(31, 0, 1, 32),
				Rect2i(2, 18, 11, 2),
				Rect2i(19, 18, 11, 2),
				Rect2i(9, 12, 2, 6),
				Rect2i(21, 12, 2, 6),
				Rect2i(5, 3, 3, 10),
				Rect2i(24, 3, 3, 10)
			],
			"enemies": [
				{"type": "boss", "position": Vector2i(15, 10)}
			]
		}
	]
