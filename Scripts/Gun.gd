extends Node2D

signal gun_shoots(pos, ammo)


@export var shooting_speed = 10  # frames between shoots
var shooting_cooldown = 0


@onready var rifle_exit: Marker2D = $Marker2D


var bullet_scene: PackedScene = preload("res://Scenes/bullet.tscn")






# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.

func _physics_process(delta):
	
	if shooting_cooldown > 0:
		shooting_cooldown -= 1
	if Input.is_action_pressed("KEY_SHOOT") and shooting_cooldown == 0:
		shooting_cooldown = shooting_speed
		emit_signal("gun_shoots", rifle_exit.global_position, bullet_scene)
	
