extends CharacterBody2D

@export var speed := 60
@export var max_hp := 6
@export var damage := 1

var hp := max_hp
var player := null

func _ready():
    player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
    if player == null:
        return

    var dir = (player.global_position - global_position).normalized()
    velocity = dir * speed
    move_and_slide()

func take_damage(amount):
    hp -= amount
    if hp <= 0:
        die()

func die():
    queue_free()

func _on_hit_player(body):
    if body.name == "Player":
        body.take_damage(damage)
