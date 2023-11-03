extends RigidBody2D

@export var rotation_speed = 1500


var rotation_direction = 0


# Called when the node enters the scene tree for the first time.

func _physics_process(_delta):
	apply_torque(Input.get_axis("KEY_ROTATE_LEFT", "KEY_ROTATE_RIGHT") * rotation_speed)
	
	#print(angular_velocity)
