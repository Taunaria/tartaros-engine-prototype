extends Node2D
class_name BlockTile

const IsoMapper := preload("res://scripts/core/iso.gd")
const TILE_WIDTH := IsoMapper.RENDER_TILE_WIDTH
const TILE_HEIGHT := IsoMapper.RENDER_TILE_HEIGHT
const BlockFaceAtlas := preload("res://scripts/visual/block_face_atlas.gd")

var grid_position: Vector2i = Vector2i.ZERO
var tile_type: String = "grass"
var render_origin: Vector2 = Vector2.ZERO

@onready var top_sprite: Sprite2D = $TopSprite
@onready var left_sprite: Sprite2D = $LeftSprite
@onready var right_sprite: Sprite2D = $RightSprite


func _ready() -> void:
	var face_texture: Texture2D = BlockFaceAtlas.get_texture()
	top_sprite.texture = face_texture
	left_sprite.texture = face_texture
	right_sprite.texture = face_texture
	top_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	left_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	right_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_face_regions()
	_layout_faces()


func setup(new_tile_type: String, new_grid_position: Vector2i, new_render_origin: Vector2 = Vector2.ZERO) -> void:
	tile_type = new_tile_type
	grid_position = new_grid_position
	render_origin = new_render_origin
	position = render_origin + grid_to_screen(grid_position)
	z_index = grid_position.x + grid_position.y
	if is_node_ready():
		_apply_face_regions()
		_layout_faces()


static func grid_to_screen(cell: Vector2i) -> Vector2:
	return IsoMapper.grid_to_screen(cell)


func _apply_face_regions() -> void:
	var face_regions: Dictionary = BlockFaceAtlas.get_regions()
	var face_info: Dictionary = face_regions.get(tile_type, face_regions["grass"])
	top_sprite.region_enabled = true
	left_sprite.region_enabled = true
	right_sprite.region_enabled = true
	top_sprite.region_rect = face_info["top_texture_region"]
	left_sprite.region_rect = face_info["left_texture_region"]
	right_sprite.region_rect = face_info["right_texture_region"]


func _layout_faces() -> void:
	top_sprite.centered = true
	left_sprite.centered = true
	right_sprite.centered = true
	top_sprite.position = Vector2(0, 0)
	left_sprite.position = Vector2(-16, 16)
	right_sprite.position = Vector2(16, 16)
	top_sprite.z_index = 2
	left_sprite.z_index = 0
	right_sprite.z_index = 1
