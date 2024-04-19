extends Node

"""
ESC - Return to the previous menu interface
~ - Game Menu
F1 - Exit Game
F2 - maximize window
F3 - toggle cheat mode
F4 - toggle visibility of collision shapes

F5 - Save
F6 - Load
"""

@onready var ui = $".."



func _process(_delta):
	if Input.is_action_just_pressed("KEY_EXIT_GAME"):
		_on_quit_pressed()

	if Input.is_action_just_pressed("KEY_MAXIMIZE_WINDOW"):
		_on_full_screen_pressed()

	if Input.is_action_just_pressed("KEY_MENU"):
		_toggle_menu_status()

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



#region Buttons

func _on_back_to_game_pressed():
	_toggle_menu_status()


func _on_full_screen_pressed():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		#DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)  # there is a grey border around the screen
		# https://github.com/godotengine/godot/issues/63500
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_quit_pressed():
	get_tree().quit()


func _on_win_battle_pressed():
	for army_idx in range(BM.fighting_units.size()):
		if army_idx == BM.participant_idx:
			continue

		for unit_idx in range(BM.fighting_units[army_idx].size() - 1, -1, -1):
			BM.kill_unit(BM.fighting_units[army_idx][unit_idx])

	_toggle_menu_status()


func _on_surrender_pressed():
	for unit_idx in range(BM.fighting_units[BM.participant_idx].size() - 1, -1, -1):
		BM.kill_unit(BM.fighting_units[BM.participant_idx][unit_idx])

	_toggle_menu_status()


func _on_return_to_main_menu_pressed():
	_toggle_menu_status()
	IM.go_to_main_menu()

#endregion


#region Tools

func _toggle_menu_status():
	ui.visible = not ui.visible

	get_tree().paused = not get_tree().paused
	# get_tree().set_deferred("paused", ui.visible)  # TODO research the difference

#endregion
