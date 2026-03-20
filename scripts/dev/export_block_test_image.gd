extends SceneTree

const BlockFaceAtlas := preload("res://scripts/visual/block_face_atlas.gd")
const BlockTile := preload("res://scripts/visual/block_tile.gd")
const OUTPUT_PATH := "res://tmp/block_render_test_export.png"
const ORIGIN := Vector2i(352, 120)
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


func _initialize() -> void:
	var atlas_texture: Texture2D = BlockFaceAtlas.get_texture()
	var atlas_image: Image = atlas_texture.get_image()
	var output := Image.create(1024, 768, false, Image.FORMAT_RGBA8)
	output.fill(Color8(242, 245, 250))

	var draw_list: Array[Dictionary] = []
	for y in range(TEST_GRID.size()):
		for x in range(TEST_GRID[y].size()):
			draw_list.append({
				"type": TEST_GRID[y][x],
				"grid": Vector2i(x, y),
				"sort": x + y
			})

	draw_list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["sort"] < b["sort"]
	)

	for entry in draw_list:
		_draw_block(output, atlas_image, entry["type"], entry["grid"])

	_draw_marker(output, Vector2i(4, 4), Color8(204, 82, 82))
	_draw_marker(output, Vector2i(7, 2), Color8(86, 145, 102))
	output.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	quit()


func _draw_block(output: Image, atlas_image: Image, tile_type: String, grid: Vector2i) -> void:
	var regions: Dictionary = BlockFaceAtlas.get_regions()[tile_type]
	var screen: Vector2 = BlockTile.grid_to_screen(grid)
	var screen_origin := Vector2i(roundi(screen.x), roundi(screen.y)) + ORIGIN

	_blit_region(output, atlas_image, regions["left_texture_region"], screen_origin + Vector2i(-32, 0))
	_blit_region(output, atlas_image, regions["right_texture_region"], screen_origin + Vector2i(0, 0))
	_blit_region(output, atlas_image, regions["top_texture_region"], screen_origin + Vector2i(-32, -16))


func _blit_region(output: Image, atlas_image: Image, region: Rect2, destination: Vector2i) -> void:
	for y in range(int(region.size.y)):
		for x in range(int(region.size.x)):
			var src_x := int(region.position.x) + x
			var src_y := int(region.position.y) + y
			var dst_x := destination.x + x
			var dst_y := destination.y + y
			if dst_x < 0 or dst_y < 0 or dst_x >= output.get_width() or dst_y >= output.get_height():
				continue
			var color: Color = atlas_image.get_pixel(src_x, src_y)
			if color.a <= 0.0:
				continue
			output.set_pixel(dst_x, dst_y, color)


func _draw_marker(output: Image, grid: Vector2i, color: Color) -> void:
	var screen: Vector2 = BlockTile.grid_to_screen(grid)
	var position := Vector2i(roundi(screen.x), roundi(screen.y)) + ORIGIN
	_fill_rect(output, Rect2i(position.x - 10, position.y + 14, 20, 8), Color(0, 0, 0, 0.18))
	_fill_rect(output, Rect2i(position.x - 8, position.y - 22, 16, 24), color)
	_fill_rect(output, Rect2i(position.x - 6, position.y - 34, 12, 12), color.lightened(0.2))


func _fill_rect(output: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if x < 0 or y < 0 or x >= output.get_width() or y >= output.get_height():
				continue
			output.set_pixel(x, y, color)
