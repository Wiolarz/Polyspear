extends Node


@export var reset_save = false


var player_file = "user://save.tres"


func load_game():
	var save = load(player_file)
	if save:
		Bus.load_game.emit(save)

func save_game():
	var save = Save.new()
	Bus.collect_save_data.emit(save)
	#print(save)
	var info = ResourceSaver.save(save, player_file)
	if info != OK:
		print(info)
	#print("saved game")


#func save():
	#var save = Save.new()
	#save.position = get_node("%Player").position


func _process(_delta):
	if Input.is_action_just_pressed("KEY_SAVE_GAME"):
		save_game()
	
	if Input.is_action_just_pressed("KEY_LOAD_GAME"):
		load_game()
