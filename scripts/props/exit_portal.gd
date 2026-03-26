extends Area2D

const IsoMapper := preload("res://scripts/core/iso.gd")
const ItemVisuals := preload("res://scripts/visual/item_visuals.gd")
const PORTAL_DRAW_SIZE := Vector2(108, 126)
const PORTAL_DRAW_OFFSET := Vector2(-54, -92)

var game: Node = null
var level_name: String = ""
var next_level_id: String = ""
var locked: bool = true
var render_origin: Vector2 = Vector2.ZERO


func setup(game_ref: Node, target_level_id: String, label: String) -> void:
	game = game_ref
	next_level_id = target_level_id
	level_name = label
	queue_redraw()


func set_locked(value: bool) -> void:
	locked = value
	queue_redraw()


func set_active(_active: bool) -> void:
	pass


func set_render_origin(new_render_origin: Vector2) -> void:
	render_origin = new_render_origin
	z_index = 1000 + IsoMapper.entity_sort_z_for_foot(global_position) + 1
	queue_redraw()


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _draw() -> void:
	var base: Vector2 = IsoMapper.render_offset(position, render_origin)
	var texture: Texture2D = ItemVisuals.get_portal_texture(not locked)
	if texture != null:
		draw_texture_rect(texture, Rect2(base + PORTAL_DRAW_OFFSET, PORTAL_DRAW_SIZE), false)
		return

	var frame_color: Color = Color8(74, 55, 34)
	var portal_color: Color = Color8(93, 188, 217) if not locked else Color8(52, 58, 66)
	draw_rect(Rect2(base + Vector2(-34, -54), Vector2(68, 70)), frame_color)
	draw_rect(Rect2(base + Vector2(-24, -46), Vector2(48, 56)), portal_color)


func _on_body_entered(body: Node) -> void:
	if locked or not body.is_in_group("player") or game == null:
		return

	locked = true
	monitoring = false
	collision_layer = 0
	collision_mask = 0
	if game.has_method("advance_to_level_via_portal"):
		game.advance_to_level_via_portal(self, next_level_id)
	elif game.has_method("advance_to_level_id"):
		game.advance_to_level_id(next_level_id)
