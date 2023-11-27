"""
ESC - exit game
F1 - restart level
F2 - maximize window
F3 - cheat codes (immortality)
"""

extends Node


var maximize = false
var player_file = "user://save.tres"

func _ready():
	load_game.call_deferred()
	if maximize:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	

func load_game():
	var save = load(player_file)
	if save:
		Bus.load_game.emit(save)

func save_game():
	var save = Save.new()
	Bus.collect_save_data.emit(save)
	print(save)
	print(ResourceSaver.save(save, player_file))
	print("co")


func _process(_delta):
	if Input.is_action_just_pressed("EXIT_GAME"):
		print("wtf")
		save_game()
		get_tree().quit.call_deferred()
	
	if Input.is_action_just_pressed("RESTART_LEVEL"):
		get_tree().reload_current_scene()
	
	if Input.is_action_just_pressed("PAUSE"):
		get_tree().paused = not get_tree().paused
		
	if Input.is_action_just_pressed("SAVE"):
		save_game()
	
	if Input.is_action_just_pressed("LOAD"):
		load_game()
	
	
	
	if Input.is_action_just_pressed("MAXIMIZE_WINDOW"):
		if not maximize:
			maximize = true
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			#DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)  # there is a grey border around the screen 
			# https://github.com/godotengine/godot/issues/63500
		else:
			maximize = false
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
