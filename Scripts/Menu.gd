"""
ESC - exit game
F1 - restart level
F2 - maximize window
F3 - cheat codes (immortality)
"""

extends Node


@export var maximize = false
# TODO add check for global project settings in ready


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
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			maximize = false
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

