extends Node2D
class_name BlockTile

const IsoMapper := preload("res://scripts/core/iso.gd")
const TILE_WIDTH := IsoMapper.RENDER_TILE_WIDTH
const TILE_HEIGHT := IsoMapper.RENDER_TILE_HEIGHT
const BlockFaceAtlas := preload("res://scripts/visual/block_face_atlas.gd")
const DEFAULT_HEIGHT_STEP := 32.0

var grid_position: Vector2i = Vector2i.ZERO
var tile_type: String = "grass"
var render_origin: Vector2 = Vector2.ZERO
var visual_height: int = 0
var height_step: float = DEFAULT_HEIGHT_STEP


func _ready() -> void:
	_rebuild_visuals()


func setup(
		new_tile_type: String,
		new_grid_position: Vector2i,
		new_render_origin: Vector2 = Vector2.ZERO,
		new_visual_height: int = 0
) -> void:
	tile_type = new_tile_type
	grid_position = new_grid_position
	render_origin = new_render_origin
	visual_height = maxi(new_visual_height, 0)
	position = render_origin + grid_to_screen(grid_position)
	z_index = _get_base_z_index()
	if is_node_ready():
		_rebuild_visuals()


static func grid_to_screen(cell: Vector2i) -> Vector2:
	return IsoMapper.grid_to_screen(cell)


static func get_default_height_step() -> float:
	var face_regions: Dictionary = BlockFaceAtlas.get_regions()
	var sample_region: Rect2 = face_regions["stone"]["left_texture_region"]
	return sample_region.size.y


func _get_base_z_index() -> int:
	return (grid_position.x + grid_position.y) * 10


func _rebuild_visuals() -> void:
	for child in get_children():
		child.queue_free()

	height_step = get_default_height_step()
	var face_texture: Texture2D = BlockFaceAtlas.get_texture()
	var face_regions: Dictionary = BlockFaceAtlas.get_regions()
	var face_info: Dictionary = face_regions.get(tile_type, face_regions["grass"])

	if visual_height <= 0:
		_add_face_sprite(face_texture, face_info["top_texture_region"], Vector2.ZERO, 2)
		return

	for layer in range(visual_height):
		var layer_offset := Vector2(0, -height_step * float(layer + 1))
		var layer_z := layer * 3
		_add_face_sprite(face_texture, face_info["left_texture_region"], layer_offset + Vector2(-16, 16), layer_z)
		_add_face_sprite(face_texture, face_info["right_texture_region"], layer_offset + Vector2(16, 16), layer_z + 1)

	var top_offset := Vector2(0, -height_step * float(visual_height))
	_add_face_sprite(face_texture, face_info["top_texture_region"], top_offset, visual_height * 3 + 2)


func _add_face_sprite(texture: Texture2D, region: Rect2, sprite_position: Vector2, sprite_z: int) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.centered = true
	sprite.position = sprite_position
	sprite.z_index = sprite_z
	add_child(sprite)
