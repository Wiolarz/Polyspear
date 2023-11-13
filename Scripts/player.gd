extends CharacterBody2D

@export var speed = 10
@export var hor_speed = 1  # multiplier
@export var ver_speed = 0.5 # multiplier

func _ready():
	pass 


func movement():
	position.x += Input.get_axis("KEY_LEFT", "KEY_RIGHT") * speed * hor_speed
	position.y += Input.get_axis("KEY_DOWN", "KEY_UP") * speed * ver_speed



func _physics_process(delta):
	movement()

