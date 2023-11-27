"""
ESC - exit game
F1 - restart level
F2 - maximize window
F3 - cheat codes (immortality)
"""

extends Node


var maximize = false

func _ready():
	if maximize:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)



func _process(_delta):
	if Input.is_action_just_pressed("EXIT_GAME"):
		get_tree().quit()
	
	if Input.is_action_just_pressed("RESTART_LEVEL"):
		get_tree().reload_current_scene()
	
	if Input.is_action_just_pressed("MAXIMIZE_WINDOW"):
		if not maximize:
			maximize = true
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			#DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)  # there is a grey border around the screen 
			# https://github.com/godotengine/godot/issues/63500
		else:
			maximize = false
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
