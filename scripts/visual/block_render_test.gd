extends Node2D

const BlockTileScene := preload("res://scenes/visual/BlockTile.tscn")
const EntityMarkerScene := preload("res://scenes/visual/EntityMarker.tscn")

const TEST_GRID := [
	[{"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}],
	[{"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}],
	[{"type": "grass", "height": 0}, {"type": "wood", "height": 1}, {"type": "wood", "height": 1}, {"type": "wood", "height": 1}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "wood", "height": 2}, {"type": "wood", "height": 2}, {"type": "wood", "height": 2}, {"type": "grass", "height": 0}],
	[{"type": "grass", "height": 0}, {"type": "wood", "height": 1}, {"type": "grass", "height": 0}, {"type": "wood", "height": 1}, {"type": "dirt", "height": 0}, {"type": "dirt", "height": 0}, {"type": "wood", "height": 2}, {"type": "grass", "height": 0}, {"type": "wood", "height": 2}, {"type": "grass", "height": 0}],
	[{"type": "grass", "height": 0}, {"type": "wood", "height": 1}, {"type": "grass", "height": 0}, {"type": "wood", "height": 1}, {"type": "dirt", "height": 0}, {"type": "dirt", "height": 0}, {"type": "wood", "height": 2}, {"type": "grass", "height": 0}, {"type": "wood", "height": 2}, {"type": "stone", "height": 2}],
	[{"type": "grass", "height": 0}, {"type": "wood", "height": 1}, {"type": "wood", "height": 1}, {"type": "wood", "height": 1}, {"type": "dirt", "height": 0}, {"type": "dirt", "height": 0}, {"type": "wood", "height": 2}, {"type": "wood", "height": 2}, {"type": "wood", "height": 2}, {"type": "grass", "height": 0}],
	[{"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "dirt", "height": 0}, {"type": "dirt", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}],
	[{"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "stone", "height": 1}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}],
	[{"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}],
	[{"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}, {"type": "grass", "height": 0}]
]

const ORIGIN := Vector2(352, 170)

@onready var tiles_root: Node2D = $TilesRoot
@onready var entities_root: Node2D = $EntitiesRoot


func _ready() -> void:
	tiles_root.position = ORIGIN
	entities_root.position = ORIGIN
	_build_tiles()
	_spawn_marker(Vector2i(4, 6), "Player", Color8(204, 82, 82))
	_spawn_marker(Vector2i(8, 4), "Pillar", Color8(86, 145, 102))


func _build_tiles() -> void:
	for y in range(TEST_GRID.size()):
		var row: Array = TEST_GRID[y]
		for x in range(row.size()):
			var tile_data: Dictionary = row[x]
			var tile := BlockTileScene.instantiate()
			tiles_root.add_child(tile)
			tile.setup(_resolve_tile_type(tile_data.get("type", "grass")), Vector2i(x, y), Vector2.ZERO, tile_data.get("height", 0))


func _spawn_marker(cell: Vector2i, marker_label: String, marker_color: Color) -> void:
	var marker := EntityMarkerScene.instantiate()
	entities_root.add_child(marker)
	marker.setup(cell, marker_label, marker_color)


func _resolve_tile_type(tile_type: String) -> String:
	if tile_type == "dirt":
		return "wood"
	return tile_type
