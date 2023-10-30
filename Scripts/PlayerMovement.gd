extends RigidBody2D


@export var speed = 4


func get_input():
	
	
	
	linear_velocity += transform.y * Input.get_axis("KEY_UP", "KEY_DOWN") * speed

	linear_velocity += transform.x * Input.get_axis("KEY_LEFT", "KEY_RIGHT") * speed



func _physics_process(_delta):
	get_input()
	
