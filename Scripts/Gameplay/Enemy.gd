extends Node2D


signal bullet(pos, dir, bullet_scene, bullet_owner)

@onready var bullet_manager = $"../../BulletManager"

func movement():
	position.x -= 1


func _physics_process(delta):
	movement()
	


func _on_gun_turret_turret_shoots(pos, dir, bullet_sc):
	bullet_manager._on_player_bullet(pos, dir, bullet_sc, $hitbox)
	#emit_signal("bullet", pos, dir, bullet_sc, $hitbox)

func _on_hitbox_death():
	queue_free()
