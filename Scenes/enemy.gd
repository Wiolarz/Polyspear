extends Node2D


@export var health = 100



@onready var move_tool = $EnemyMovement
@onready var rotate_tool = $Weapon/WeaponBody


@export var speed = 2


@export var player : Node2D

func _ready():
	player = player.get_node("PlayerMovement")


func _physics_process(_delta):
	
	#direction
	var p_direction = fmod(rad_to_deg(position.angle_to_point(player.global_position)) + 360, 360) # - 360
	var current_rotation = fmod(rotate_tool.rotation_degrees + 360, 360)
	var goal_direction = p_direction - current_rotation
	#if goal_direction > 300:
		#print(goal_direction)

	print(goal_direction, "  ", p_direction, "   ", current_rotation)
	
	#var cos = 360 - p_direction 
	if goal_direction > 180:
		goal_direction *= -1	
	#if goal_direction + cos > abs(current_rotation - goal_direction):
	#	goal_direction *= -1
	
	rotate_tool.direction_change(clamp(goal_direction, -1, 1))


	# movment
	#move_tool.linear_velocity += move_tool.transform.y * clamp(player.global_position.x - move_tool.global_position.x, -1, 1) * speed

	#move_tool.linear_velocity += move_tool.transform.x * clamp(player.global_position.y - move_tool.global_position.y, -1, 1) * speed






func _on_character_hitbox_got_hit(value):
	health -= value
	print("enemy", health)
	if health <= 0:
		queue_free()
