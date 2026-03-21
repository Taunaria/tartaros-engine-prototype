extends Node2D
class_name BlockTile

const IsoMapper := preload("res://scripts/core/iso.gd")
const BlockFaceAtlas := preload("res://scripts/visual/block_face_atlas.gd")

const TILE_WIDTH := IsoMapper.RENDER_TILE_WIDTH
const TILE_HEIGHT := IsoMapper.RENDER_TILE_HEIGHT
const HALF_TILE_WIDTH := TILE_WIDTH * 0.5
const HALF_TILE_HEIGHT := TILE_HEIGHT * 0.5
const DEFAULT_HEIGHT_STEP := HALF_TILE_HEIGHT

var grid_position: Vector2i = Vector2i.ZERO
var tile_type: String = "grass"
var render_origin: Vector2 = Vector2.ZERO
var visual_height: int = 0
var height_step: float = DEFAULT_HEIGHT_STEP
var include_top_face: bool = true
var include_side_faces: bool = true
var side_trim_top_pixels: int = 0
var left_face_visible_from_layer: int = 0
var right_face_visible_from_layer: int = 0


func _ready() -> void:
	_rebuild_visuals()


func setup(
		new_tile_type: String,
		new_grid_position: Vector2i,
		new_render_origin: Vector2 = Vector2.ZERO,
		new_visual_height: int = 0,
		new_include_top_face: bool = true,
		new_include_side_faces: bool = true,
		new_side_trim_top_pixels: int = 0,
		new_left_face_visible_from_layer: int = 0,
		new_right_face_visible_from_layer: int = 0
) -> void:
	tile_type = new_tile_type
	grid_position = new_grid_position
	render_origin = new_render_origin
	visual_height = maxi(new_visual_height, 0)
	include_top_face = new_include_top_face
	include_side_faces = new_include_side_faces
	side_trim_top_pixels = maxi(new_side_trim_top_pixels, 0)
	left_face_visible_from_layer = maxi(new_left_face_visible_from_layer, 0)
	right_face_visible_from_layer = maxi(new_right_face_visible_from_layer, 0)
	position = render_origin + grid_to_screen(grid_position)
	z_index = _get_base_z_index()
	height_step = DEFAULT_HEIGHT_STEP
	if is_node_ready():
		_rebuild_visuals()


static func grid_to_screen(cell: Vector2i) -> Vector2:
	return IsoMapper.grid_to_screen(cell)


static func get_default_height_step() -> float:
	return DEFAULT_HEIGHT_STEP


func _get_base_z_index() -> int:
	return IsoMapper.tile_sort_base(grid_position)


func _rebuild_visuals() -> void:
	for child in get_children():
		child.queue_free()

	var atlas_texture: Texture2D = BlockFaceAtlas.get_texture()
	var face_regions: Dictionary = BlockFaceAtlas.get_regions()
	var face_info: Dictionary = face_regions.get(tile_type, face_regions["grass"])

	if include_side_faces and visual_height > 0:
		for layer in range(visual_height):
			var layer_offset := Vector2(0.0, -height_step * float(layer))
			if layer >= left_face_visible_from_layer:
				_add_face_sprite(
					atlas_texture,
					face_info["left_texture_region"],
					Vector2(-HALF_TILE_WIDTH * 0.5, layer_offset.y),
					layer * 3,
					side_trim_top_pixels
				)
			if layer >= right_face_visible_from_layer:
				_add_face_sprite(
					atlas_texture,
					face_info["right_texture_region"],
					Vector2(HALF_TILE_WIDTH * 0.5, layer_offset.y),
					layer * 3 + 1,
					side_trim_top_pixels
				)

	if include_top_face:
		var top_offset := Vector2(0.0, -height_step * float(visual_height))
		_add_face_sprite(atlas_texture, face_info["top_texture_region"], top_offset, visual_height * 3 + 2)


func _add_face_sprite(
	texture: Texture2D,
	region: Rect2,
	sprite_position: Vector2,
	sprite_z: int,
	trim_top_pixels: int = 0
) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.region_enabled = true
	var final_region: Rect2 = region
	var final_position: Vector2 = sprite_position
	if trim_top_pixels > 0 and trim_top_pixels < int(region.size.y):
		final_region.position.y += trim_top_pixels
		final_region.size.y -= trim_top_pixels
		final_position.y += float(trim_top_pixels) * 0.5
	sprite.region_rect = final_region
	sprite.centered = true
	sprite.position = final_position
	sprite.z_index = sprite_z
	add_child(sprite)
