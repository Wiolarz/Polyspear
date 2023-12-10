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


func _physics_process(delta):
	movement()
	


func _on_gun_turret_turret_shoots(pos, dir, bullet_sc):
	bullet_manager._on_player_bullet(pos, dir, bullet_sc, $hitbox)
	#emit_signal("bullet", pos, dir, bullet_sc, $hitbox)

func _on_hitbox_death():
	queue_free()
