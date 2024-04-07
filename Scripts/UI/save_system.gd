extends Node

@export var reset_save = false


"""
Save system could be deactivated by the GAME_MENU Manager
To allow saving only after entering the menu, while the game is paused
"""
func _process(_delta):
	if Input.is_action_just_pressed("KEY_SAVE_GAME"):
		print("quick save is not yet supported")
	
	if Input.is_action_just_pressed("KEY_LOAD_GAME"):
		print("quick load is not yet supported")
