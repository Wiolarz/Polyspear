extends Node2D

#@export var player : Node2D

# inteval (in seconds) in which spawnrate increases by 1 seconds
@export var difficulty_tempo = 10
@export var difficulty_increase = 1

# spawnrate in frames (60 per seconds)
@export var spawnrate = 240

var enemies = 0
var seconds = 0

@export var enemy_scene = load("res://Scenes/small_enemy.tscn")
#@onready var enemy = enemy_scene.instantiate()
var countdown = 0



func spawn():
	var enemy = enemy_scene.instantiate()
	add_child(enemy)

	#var side = 8000
	#if randf() > 0.5:
	#	side = -4000
	#enemy.position = Vector2(side, randf_range(-4000, 4000))


func _physics_process(delta):
	countdown += 1
	# TODO something is broken with spawn system
	# TODO make it so that a greater spawn system places dudes into specified spawn points (also make another code that places enemies randomly)

	if countdown % 60 == 0:
		seconds += 1
		#print("time: ", seconds)
		if seconds % difficulty_tempo == 0:
			if spawnrate > 30: # 30 hard coded minimum time between spawn 
				spawnrate -= difficulty_increase
				if spawnrate < 30:
					spawnrate = 30
			

	
	
	if countdown % spawnrate == 0:
		enemies += 1
		#print(enemies)
		spawn()

	
		

