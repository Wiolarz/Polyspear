extends Node2D

@export var player : Node2D


var enemy_scene = load("res://Scenes/small_enemy.tscn")
#@onready var enemy = enemy_scene.instantiate()
var countdown = 0



func spawn():
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	var side = 8000
	if randf() > 0.5:
		side = -4000
	enemy.position = Vector2(side, randf_range(-4000, 4000))


	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	countdown += 1

	if countdown % 60 == 1:
		spawn()

