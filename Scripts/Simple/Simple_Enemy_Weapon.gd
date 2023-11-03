extends RigidBody2D


@export var rotation_speed = 0.3


var rotation_direction = 0

func direction_change(value):
	rotation_direction = value

func _physics_process(_delta):
	angular_velocity += rotation_direction * rotation_speed