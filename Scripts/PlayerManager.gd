extends Node2D

@export var health = 100

@export var cheats = false


func _process(_delta):
	if Input.is_action_just_pressed("CHEAT_MODE"):
		if cheats:
			cheats = false
		else:
			cheats = true

func _on_character_hitbox_got_hit(value):
	if not cheats:
		health -= value
		print("player", health)
	
	if health <= 0:
		get_tree().reload_current_scene()
