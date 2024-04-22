extends Node2D



@export var enemy_scene = load("res://Scenes/Latest/small_enemy.tscn")
#@onready var enemy = enemy_scene.instantiate()

func spawn():
	var enemy = enemy_scene.instantiate()
	add_child(enemy)

	#var side = 8000
	#if randf() > 0.5:
	#	side = -4000
	#enemy.position = Vector2(side, randf_range(-4000, 4000))


var not_yet = true

func _physics_process(_delta):
	if not_yet:
		spawn()
		not_yet = false




