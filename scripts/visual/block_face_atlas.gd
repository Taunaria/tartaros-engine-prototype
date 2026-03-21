extends RefCounted
class_name BlockFaceAtlas

const FACE_REGIONS := {
	"grass": {
		"top_texture_region": Rect2(0, 0, 64, 32),
		"left_texture_region": Rect2(64, 0, 32, 32),
		"right_texture_region": Rect2(96, 0, 32, 32)
	},
	"dirt": {
		"top_texture_region": Rect2(0, 32, 64, 32),
		"left_texture_region": Rect2(64, 32, 32, 32),
		"right_texture_region": Rect2(96, 32, 32, 32)
	},
	"wood": {
		"top_texture_region": Rect2(0, 64, 64, 32),
		"left_texture_region": Rect2(64, 64, 32, 32),
		"right_texture_region": Rect2(96, 64, 32, 32)
	},
	"light_stone": {
		"top_texture_region": Rect2(0, 96, 64, 32),
		"left_texture_region": Rect2(64, 96, 32, 32),
		"right_texture_region": Rect2(96, 96, 32, 32)
	},
	"dark_stone": {
		"top_texture_region": Rect2(0, 128, 64, 32),
		"left_texture_region": Rect2(64, 128, 32, 32),
		"right_texture_region": Rect2(96, 128, 32, 32)
	},
	"foliage": {
		"top_texture_region": Rect2(0, 160, 64, 32),
		"left_texture_region": Rect2(64, 160, 32, 32),
		"right_texture_region": Rect2(96, 160, 32, 32)
	},
	"temple_stone": {
		"top_texture_region": Rect2(0, 192, 64, 32),
		"left_texture_region": Rect2(64, 192, 32, 32),
		"right_texture_region": Rect2(96, 192, 32, 32)
	},
	"lava": {
		"top_texture_region": Rect2(0, 224, 64, 32),
		"left_texture_region": Rect2(64, 224, 32, 32),
		"right_texture_region": Rect2(96, 224, 32, 32)
	},
	"cracked": {
		"top_texture_region": Rect2(0, 256, 64, 32),
		"left_texture_region": Rect2(64, 256, 32, 32),
		"right_texture_region": Rect2(96, 256, 32, 32)
	},
	"forest_grass": {
		"top_texture_region": Rect2(0, 288, 64, 32),
		"left_texture_region": Rect2(64, 288, 32, 32),
		"right_texture_region": Rect2(96, 288, 32, 32)
	}
}

const ATLAS_TEXTURE := preload("res://assets/textures/block_faces.svg")


static func get_regions() -> Dictionary:
	return FACE_REGIONS


static func get_texture() -> Texture2D:
	return ATLAS_TEXTURE
