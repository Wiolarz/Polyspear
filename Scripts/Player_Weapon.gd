extends RigidBody2D

@export var rotation_speed = 1.5


var rotation_direction = 0


# Called when the node enters the scene tree for the first time.

func _physics_process(_delta):
	rotation_direction = Input.get_axis("KEY_ROTATE_LEFT", "KEY_ROTATE_RIGHT")
	angular_velocity += rotation_direction * rotation_speed

	
	#print(angular_velocity)