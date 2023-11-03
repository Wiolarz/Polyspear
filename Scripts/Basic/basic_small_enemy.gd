"""
Enemy characters:
health manager
movement AI
"""

extends Node2D


@export var health = 100


# shortcuts to operate on enemy body parts
@onready var body = $EnemyMovement
@onready var weapon = $Weapon/WeaponBody

@export var speed = 8

var player : RigidBody2D  # reference to Player position


func _ready():
	player = $"../../Player/PlayerMovement"  # get a reference to Player position
	


func _physics_process(_delta):
	
	weapon.look_at(player.global_position)
	
	
	
	
#	var p_direction = fmod(rad_to_deg(move_tool.global_position.angle_to_point(player.global_position)) + 360, 360) # - 360
#	var current_rotation = fmod(rotate_tool.rotation_degrees + 360, 360)
#	var goal_direction = p_direction - current_rotation
#	goal_direction = fmod(goal_direction + 360, 360)
#
#	if goal_direction > 180:
#		goal_direction -= 360
#
#	print(goal_direction, "  ", p_direction, "   ", current_rotation)
#
#
#	rotate_tool.direction_change(clamp(goal_direction, -1, 1))
	
	
	
	
	
	
	#direction
#	var player_direction = fmod(rad_to_deg(move_tool.global_position.angle_to_point(player.global_position)) + 360, 360)
#	var current_rotation = fmod(rotate_tool.rotation_degrees + 360, 360)
#	var goal_angle = player_direction - current_rotation
#	#if goal_direction > 300:
#		#print(goal_direction)
#
#	print(goal_angle, "  ", player_direction, "   ", current_rotation)
#
#
#
##	if fmod(360.0 + goal_angle - current_rotation, 360.0) > 180.0:
##		goal_angle *= -1
#
#	var cos = 360 - player_direction
#	if goal_angle > 300 and goal_angle > cos:
#		goal_angle *= -1
#
#
#	#if goal_direction + cos > abs(current_rotation - goal_direction):
#	#	goal_direction *= -1
#
#	rotate_tool.direction_change(clamp(goal_angle, -1, 1))


	# movment
	var pdir = (player.global_position - body.global_position).normalized() * speed
	body.move_and_slide(pdir)





func _on_character_hitbox_got_hit(value):
	health -= value
	print("enemy", health)
	if health <= 0:
		queue_free()
