"""
Enemy characters:
health manager
movement AI
"""

extends Node2D


@export var health = 100


# shortcuts to operate on enemy body parts
@onready var move_tool = $EnemyMovement
@onready var body = $Weapon/WeaponBody

@export var speed = 40

var player : RigidBody2D  # reference to Player position


func _ready():
	player = $"../../Player/PlayerMovement"  # get a reference to Player position
	


func _physics_process(_delta):
	
	var p_direction = fmod(rad_to_deg(move_tool.global_position.angle_to_point(player.global_position)) + 360, 360) # - 360
	var current_rotation = fmod(body.rotation_degrees + 360, 360)
	var goal_direction = p_direction - current_rotation


	#print(goal_direction, "  ", p_direction, "   ", current_rotation)

	if abs(goal_direction) > 180:
		goal_direction *= -1


	body.direction_change(clamp(goal_direction, -1, 1))
	
	


	# movment
	var target_goal = Vector2(clamp(player.global_position.x - body.global_position.x, -1, 1), clamp(player.global_position.y - body.global_position.y, -1, 1))
	
	body.linear_velocity += transform.y * speed * clamp(target_goal.y, -1, 1) 
	body.linear_velocity += transform.x * speed * clamp(target_goal.x, -1, 1) 





func _on_character_hitbox_got_hit(value):
	health -= value
	#print("enemy", health)
	if health <= 0:
		Score.value += 1
		queue_free()
