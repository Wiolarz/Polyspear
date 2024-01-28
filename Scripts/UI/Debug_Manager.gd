"""
ESC - exit game
F1 - restart level
F2 - maximize window
F3 - cheat codes (immortality)
"""

extends Node



var maximize = false

@onready var ui = $".."

func _ready():
	if maximize:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)







func _process(_delta):
	if Input.is_action_just_pressed("KEY_EXIT_GAME"):
		get_tree().quit()
		#get_tree().quit.call_deferred()  # In case normal quit doesnt work properly with save system TRY THIS
	
	if Input.is_action_just_pressed("KEY_RESTART_LEVEL"):
		get_tree().reload_current_scene()
	
	if Input.is_action_just_pressed("KEY_MAXIMIZE_WINDOW"):
		_on_full_screen_pressed()

	if Input.is_action_just_pressed("KEY_MENU"):
		_on_back_to_game_pressed()
	
	if Input.is_action_just_pressed("KEY_DEBUG_COLLISION_SHAPES"):
		var tree := get_tree()
		tree.debug_collisions_hint = not tree.debug_collisions_hint

		# Traverse tree to call queue_redraw on instances of
		# CollisionShape2D and CollisionPolygon2D.
		var node_stack: Array[Node] = [tree.get_root()]
		while not node_stack.is_empty():
			var node: Node = node_stack.pop_back()
			if is_instance_valid(node):
				if node is CollisionShape2D or node is CollisionPolygon2D:
					node.queue_redraw()
				if node is TileMap:
					node.collision_visibility_mode = TileMap.VISIBILITY_MODE_FORCE_HIDE
					node.collision_visibility_mode = TileMap.VISIBILITY_MODE_DEFAULT
				node_stack.append_array(node.get_children())
	
	



func _on_back_to_game_pressed():
	ui.visible = not ui.visible
	
	get_tree().paused = not get_tree().paused
	# get_tree().set_deferred("paused", ui.visible)  # TODO research the difference


func _on_restart_pressed():
	_on_back_to_game_pressed()
	get_tree().reload_current_scene()


func _on_full_screen_pressed():
		if not maximize:
			maximize = true
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			#DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)  # there is a grey border around the screen 
			# https://github.com/godotengine/godot/issues/63500
		else:
			maximize = false
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_quit_pressed():
	get_tree().quit()
