extends RefCounted
class_name BlockFaceAtlas

const FACE_REGIONS := {
	"grass": {
		"top_texture_region": Rect2(0, 0, 64, 32),
		"left_texture_region": Rect2(64, 0, 32, 32),
		"right_texture_region": Rect2(96, 0, 32, 32)
	},
	"stone": {
		"top_texture_region": Rect2(0, 32, 64, 32),
		"left_texture_region": Rect2(64, 32, 32, 32),
		"right_texture_region": Rect2(96, 32, 32, 32)
	},
	"wood": {
		"top_texture_region": Rect2(0, 64, 64, 32),
		"left_texture_region": Rect2(64, 64, 32, 32),
		"right_texture_region": Rect2(96, 64, 32, 32)
	}
}

const ATLAS_TEXTURE := preload("res://assets/textures/block_faces.svg")


static func get_regions() -> Dictionary:
	return FACE_REGIONS


static func get_texture() -> Texture2D:
	return ATLAS_TEXTURE
