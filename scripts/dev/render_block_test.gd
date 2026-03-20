extends SceneTree

const BlockRenderTestScene = preload("res://scenes/visual/BlockRenderTest.tscn")
const OUTPUT_PATH := "res://tmp/block_render_test.png"


func _initialize() -> void:
	get_root().size = Vector2i(1024, 768)
	var scene := BlockRenderTestScene.instantiate()
	get_root().add_child(scene)
	process_frame.connect(_capture_first_frame, CONNECT_ONE_SHOT)


func _capture_first_frame() -> void:
	process_frame.connect(_save_image, CONNECT_ONE_SHOT)


func _save_image() -> void:
	var image: Image = get_root().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	quit()
