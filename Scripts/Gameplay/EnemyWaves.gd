extends Node2D


var enemy_scene: PackedScene = preload("res://Scenes/enemy.tscn")

@onready var spawn_locations = $SpawnLocations.get_children()

var timer = 0

func _physics_process(_delta):
	if enemy_scene == null:
		print("null enemy")
		return


	timer += 1
	if timer == 60:
		timer = 0
		# print("spawn enemy")
		var enemy = enemy_scene.instantiate() as Node2D

		enemy.position = spawn_locations[randi_range(0, spawn_locations.size() - 1)].global_position

		add_child(enemy)
	

