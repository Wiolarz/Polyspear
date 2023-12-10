extends Node2D


@export var enemy_scene: PackedScene = preload("res://Scenes/enemy.tscn")
@export var super_enemy_scene: PackedScene = preload("res://Scenes/enemy.tscn")

@onready var spawn_locations = $SpawnLocations.get_children()



@export var enemy_spawn_rate : int = 270



var timer = enemy_spawn_rate - 1

func _physics_process(_delta):
	if enemy_scene == null:
		print("null enemy")
		return


	timer += 1
	if timer == enemy_spawn_rate:
		timer = 0
		# print("spawn enemy")
		var enemy
		if randi_range(1, 2) == 1:
			enemy = enemy_scene.instantiate() as Node2D
		else:
			enemy = super_enemy_scene.instantiate() as Node2D

		enemy.position = spawn_locations[randi_range(0, spawn_locations.size() - 1)].global_position

		add_child(enemy)
	

