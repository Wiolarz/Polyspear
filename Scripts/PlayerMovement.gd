extends RigidBody2D


@export var speed = 9000


func get_input():

	apply_force(Input.get_vector("KEY_LEFT", "KEY_RIGHT", "KEY_UP", "KEY_DOWN") * speed, global_position)




func _physics_process(_delta):
	get_input()
	
