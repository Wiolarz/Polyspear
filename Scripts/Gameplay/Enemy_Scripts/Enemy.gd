extends Node2D


signal bullet(pos, dir, bullet_scene, bullet_owner)

@export var hull : Resource
@export var turret : Resource
@export var guns : Resource


@onready var bullet_manager = $"../../BulletManager"

func _init(spd : int = 1):
	speed = spd


var speed = 1

func movement():
	position.x -= speed


func _physics_process(_delta):
	movement()
	




func _on_basic_turret_turret_shoots(pos:Variant, dir:Variant, ammo_scene:Variant):
	bullet_manager._on_player_bullet(pos, dir, ammo_scene, owner)

func _on_ship_hull_death():
	queue_free()
