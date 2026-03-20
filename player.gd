extends CharacterBody2D

@export var speed := 120
@export var max_hp := 10

var hp := max_hp
var attack_cooldown := 0.4
var attack_timer := 0.0

func _physics_process(delta):
    handle_movement(delta)
    handle_attack(delta)

func handle_movement(delta):
    var dir = Vector2.ZERO

    if Input.is_action_pressed("ui_up"):
        dir.y -= 1
    if Input.is_action_pressed("ui_down"):
        dir.y += 1
    if Input.is_action_pressed("ui_left"):
        dir.x -= 1
    if Input.is_action_pressed("ui_right"):
        dir.x += 1

    dir = dir.normalized()
    velocity = dir * speed
    move_and_slide()

func handle_attack(delta):
    attack_timer -= delta

    if Input.is_action_just_pressed("attack") and attack_timer <= 0:
        attack_timer = attack_cooldown
        perform_attack()

func perform_attack():
    var attack_area = get_node("AttackArea")

    for body in attack_area.get_overlapping_bodies():
        if body.has_method("take_damage"):
            body.take_damage(2)

func take_damage(amount):
    hp -= amount
    if hp <= 0:
        die()

func die():
    print("Player died")
    get_tree().reload_current_scene()
