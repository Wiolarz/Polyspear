extends Node2D


@export var enemy_scene: PackedScene = preload("res://Scenes/enemy.tscn")
@export var super_enemy_scene: PackedScene = preload("res://Scenes/enemy.tscn")

@onready var spawn_locations = $SpawnLocations.get_children()



@export var enemy_spawn_rate : int = 270



var timer = enemy_spawn_rate - 1

@export var bossfight : PackedScene = preload("res://Scenes/boss_fight.tscn")

var enemies_to_be_spawned

func _ready():
	timer += 200
	#spawn boss fight
	enemies_to_be_spawned = bossfight.instantiate()
	add_child(enemies_to_be_spawned)

	for enemy in enemies_to_be_spawned.get_children():
		enemy.global_position.x += 480
		enemy.process_mode = 4
		enemy.hide()
		#enemy.set_process(false)
		
	
	#enemies_to_be_spawned = bossfight.get_children()

var a = 10
var b = 10

func _process(delta):
	if a > 0:
		a -= 1
		print("a")


func _physics_process(_delta):
	if b > 0:
		b -= 1
		print("b")
	if enemy_scene == null:
		print("null enemy")
		return


	timer += 1
	
	for enemy in enemies_to_be_spawned.get_children():
		#print(enemy.global_position.x)
		#print("======")
		if enemy.global_position.x == timer:
			
			enemy.global_position.x = position.x + 520
			#print(enemy.global_position.x)
			enemy.process_mode = 0
			enemy.show()
			#enemy.set_process(true)
	

	return
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
	

