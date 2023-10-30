extends Node2D


@export var health = 100



@onready var move_tool = $EnemyMovement
@onready var rotate_tool = $Weapon/WeaponBody





func _on_character_hitbox_got_hit(value):
	health -= value
	print("enemy", health)
	if health <= 0:
		queue_free()
