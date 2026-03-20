extends CharacterBody2D

signal hp_changed(current_hp: int, max_hp: int)
signal weapon_changed(weapon_data: Dictionary)
signal died

const WeaponDB := preload("res://data/weapons/weapon_db.gd")
const IsoMapper := preload("res://scripts/core/iso.gd")

@export var move_speed := 140.0
@export var max_hp := 12

var hp := max_hp
var control_enabled := true
var weapon_inventory: Dictionary = {}
var current_weapon_id := WeaponDB.get_default_weapon_id()
var facing := Vector2.DOWN
var attack_timer := 0.0
var hit_timer := 0.0
var attack_flash_timer := 0.0
var render_origin: Vector2 = Vector2.ZERO

@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D


func _ready() -> void:
	reset_for_new_run()


func _physics_process(delta: float) -> void:
	if hit_timer > 0.0:
		hit_timer -= delta

	if attack_timer > 0.0:
		attack_timer -= delta

	if attack_flash_timer > 0.0:
		attack_flash_timer -= delta
		queue_redraw()

	if not control_enabled:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_handle_movement()
	_update_attack_area()
	_handle_attack()
	move_and_slide()
	z_index = 1000 + IsoMapper.sort_key_for_logic(global_position)


func _draw() -> void:
	var base: Vector2 = _get_render_offset()
	var body_color: Color = Color8(188, 120, 72)
	var armor_color: Color = Color8(111, 138, 171)
	if hit_timer > 0.0:
		body_color = Color8(236, 117, 117)
		armor_color = Color8(255, 200, 200)

	draw_rect(Rect2(base + Vector2(-10, 8), Vector2(20, 8)), Color(0, 0, 0, 0.18))
	draw_rect(Rect2(base + Vector2(-10, -8), Vector2(20, 16)), body_color)
	draw_rect(Rect2(base + Vector2(-8, -16), Vector2(16, 10)), armor_color)
	draw_rect(Rect2(base + Vector2(-4, -20), Vector2(8, 4)), Color8(227, 214, 179))

	if attack_flash_timer > 0.0:
		var weapon: Dictionary = get_current_weapon()
		var tip_logic: Vector2 = position + facing * float(weapon["range"])
		var tip: Vector2 = IsoMapper.logic_to_screen(tip_logic, render_origin) - position
		draw_line(base, tip, weapon["color"], 4.0)


func reset_for_new_run() -> void:
	hp = max_hp
	weapon_inventory.clear()
	unlock_weapon(WeaponDB.get_default_weapon_id(), true)
	equip_weapon(WeaponDB.get_default_weapon_id())
	attack_timer = 0.0
	hit_timer = 0.0
	attack_flash_timer = 0.0
	control_enabled = true
	emit_signal("hp_changed", hp, max_hp)
	queue_redraw()


func set_control_enabled(enabled: bool) -> void:
	control_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO


func set_render_origin(new_render_origin: Vector2) -> void:
	render_origin = new_render_origin
	z_index = 1000 + IsoMapper.sort_key_for_logic(global_position)
	queue_redraw()


func get_visual_position() -> Vector2:
	return IsoMapper.logic_to_screen(global_position, render_origin)


func unlock_weapon(weapon_id: String, silent: bool = false) -> bool:
	if weapon_inventory.has(weapon_id):
		return false

	weapon_inventory[weapon_id] = true
	if not silent:
		equip_weapon(weapon_id)
	return true


func equip_weapon(weapon_id: String) -> void:
	current_weapon_id = weapon_id
	emit_signal("weapon_changed", get_current_weapon())
	_update_attack_area()
	queue_redraw()


func get_current_weapon() -> Dictionary:
	return WeaponDB.get_weapon(current_weapon_id)


func heal(amount: int) -> int:
	var previous: int = hp
	hp = clampi(hp + amount, 0, max_hp)
	emit_signal("hp_changed", hp, max_hp)
	return hp - previous


func take_damage(amount: int) -> void:
	if hit_timer > 0.0 or hp <= 0:
		return

	hp = max(hp - amount, 0)
	hit_timer = 0.45
	emit_signal("hp_changed", hp, max_hp)
	queue_redraw()
	if hp <= 0:
		control_enabled = false
		emit_signal("died")


func _handle_movement() -> void:
	var direction: Vector2 = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

	if direction.length_squared() > 0.0:
		facing = direction.normalized()
	velocity = direction.normalized() * move_speed
	queue_redraw()


func _handle_attack() -> void:
	if not Input.is_action_just_pressed("attack"):
		return

	var weapon: Dictionary = get_current_weapon()
	if attack_timer > 0.0:
		return

	attack_timer = weapon["cooldown"]
	attack_flash_timer = 0.12
	queue_redraw()

	for body in attack_area.get_overlapping_bodies():
		if body == self:
			continue
		if body.has_method("take_damage"):
			body.take_damage(weapon["damage"])


func _update_attack_area() -> void:
	var weapon: Dictionary = get_current_weapon()
	var shape := attack_shape.shape as RectangleShape2D
	shape.size = Vector2(weapon["range"], 22.0)
	attack_area.rotation = facing.angle()
	attack_area.position = facing * (weapon["range"] * 0.5 + 10.0)


func _get_render_offset() -> Vector2:
	return IsoMapper.render_offset(position, render_origin)
