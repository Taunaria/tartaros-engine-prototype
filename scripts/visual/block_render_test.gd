extends Node2D

const BlockTileScene := preload("res://scenes/visual/BlockTile.tscn")
const EntityMarkerScene := preload("res://scenes/visual/EntityMarker.tscn")

const TEST_GRID := [
	["grass", "grass", "grass", "grass", "grass", "grass", "grass", "grass", "grass", "grass"],
	["grass", "grass", "stone", "stone", "stone", "grass", "grass", "wood", "wood", "grass"],
	["grass", "grass", "stone", "grass", "grass", "grass", "grass", "wood", "wood", "grass"],
	["grass", "grass", "stone", "grass", "wood", "wood", "grass", "grass", "grass", "grass"],
	["grass", "grass", "grass", "grass", "wood", "wood", "grass", "stone", "stone", "grass"],
	["grass", "wood", "wood", "grass", "grass", "grass", "grass", "stone", "grass", "grass"],
	["grass", "wood", "wood", "grass", "stone", "stone", "grass", "grass", "grass", "grass"],
	["grass", "grass", "grass", "grass", "stone", "grass", "grass", "wood", "wood", "grass"],
	["grass", "stone", "stone", "grass", "grass", "grass", "grass", "wood", "grass", "grass"],
	["grass", "grass", "grass", "grass", "grass", "grass", "grass", "grass", "grass", "grass"]
]

const ORIGIN := Vector2(352, 120)

@onready var tiles_root: Node2D = $TilesRoot
@onready var entities_root: Node2D = $EntitiesRoot


func _ready() -> void:
	tiles_root.position = ORIGIN
	entities_root.position = ORIGIN
	_build_tiles()
	_spawn_marker(Vector2i(4, 4), "Player", Color8(204, 82, 82))
	_spawn_marker(Vector2i(7, 2), "Enemy", Color8(86, 145, 102))


func _build_tiles() -> void:
	for y in range(TEST_GRID.size()):
		var row: Array = TEST_GRID[y]
		for x in range(row.size()):
			var tile := BlockTileScene.instantiate()
			tiles_root.add_child(tile)
			tile.setup(row[x], Vector2i(x, y))


func _spawn_marker(cell: Vector2i, marker_label: String, marker_color: Color) -> void:
	var marker := EntityMarkerScene.instantiate()
	entities_root.add_child(marker)
	marker.setup(cell, marker_label, marker_color)
