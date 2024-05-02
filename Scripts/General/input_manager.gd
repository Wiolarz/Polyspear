# Singleton - IM

extends Node

## Top level god class
## TODO: split reasonably
##
## When a player selects a hex `IM.grid_input_listener` is called
##
## there input_manager check who the current play is:
## 	1 in single player its simple check if its the player turn
## 	2 in multi player we will check if its the local machine turn,
## 		if it is then it sends the move to all users
##
## if the AI plays the move:
## 	1 in single player AI gets called to act when its their turn
## 	2 in multi GAME only HOST will call AI to make a move, and broadcast it
##
## TODO: improve code that calls AI?
## TODO: improve "switch player" code (end of turn)
## so that IM knows who current player is


## notifies when `game_setup_info` is modified
signal game_setup_info_changed

enum CameraPosition {WORLD, BATTLE}


## TODO clean up, this lobby setup is used only in networking,
## it should be universal
var game_setup_info : GameSetupInfo

var players : Array[Player] :
	get:
		return _players
	set(value):
		for p in _players:
			print("removing player ", p)
			remove_child(p)
		for p in value:
			print("adding player ", p)
			add_child(p)
		_players = value

## flag for MAP EDITOR
var draw_mode : bool = false

var raging_battle : bool

var current_camera_position = CameraPosition.WORLD

var _players : Array[Player] = []


#region Input Support

## ESC - Return to the previous menu interface
## ~ - Game Menu
## F1 - Exit Game
## F2 - maximize window
## F3 - toggle cheat mode
## F4 - toggle visibility of collision shapes
##
## F5 - Save
## F6 - Load
func _process(_delta):
	## fastest response time to player input
	if Input.is_action_just_pressed("KEY_EXIT_GAME"):
		quit_game()

	if Input.is_action_just_pressed("KEY_MAXIMIZE_WINDOW"):
		toggle_fullscreen()

	if Input.is_action_just_pressed("KEY_MENU"):
		show_in_game_menu()

	if Input.is_action_just_pressed("KEY_DEBUG_COLLISION_SHAPES"):
		toggle_collision_debug()

	if Input.is_action_just_pressed("KEY_SAVE_GAME"):
		print("quick save is not yet supported")

	if Input.is_action_just_pressed("KEY_LOAD_GAME"):
		print("quick load is not yet supported")


func _physics_process(_delta):
	## physics to prevent desync when animating + enemy bot gameplay
	if Input.is_action_just_pressed("KEY_BOT_SPEED_SLOW"):
		print("anim speed - slow")
		CFG.animation_speed_frames = CFG.AnimationSpeed.NORMAL
		CFG.bot_speed_frames = CFG.BotSpeed.FREEZE
	elif Input.is_action_just_pressed("KEY_BOT_SPEED_MEDIUM"):
		print("anim speed - medium")
		CFG.animation_speed_frames = CFG.AnimationSpeed.NORMAL
		CFG.bot_speed_frames = CFG.BotSpeed.NORMAL
	elif Input.is_action_just_pressed("KEY_BOT_SPEED_FAST"):
		print("anim speed - fast")
		CFG.animation_speed_frames = CFG.AnimationSpeed.INSTANT
		CFG.bot_speed_frames = CFG.BotSpeed.FAST

# called from TileForm mouse detection
func grid_smooth_input_listener(coord : Vector2i):
	if draw_mode:
		UI.map_editor.grid_input(coord)

# called from TileForm mouse detection
func grid_input_listener(coord : Vector2i):
	#print("tile ",coord)
	#if WM.current_player.bot_engine != null:
	#    return # its a bot turn
	if draw_mode:
		return

	if raging_battle:
		BM.grid_input(coord)
	else:
		WM.grid_input(coord)


#endregion

#region Game setup

func get_world_maps_list() -> Array[String]:
	return FileSystemHelpers.list_files_in_folder(CFG.WORLD_MAPS_PATH)

func get_battle_maps_list() -> Array[String]:
	return FileSystemHelpers.list_files_in_folder(CFG.BATTLE_MAPS_PATH)


func get_active_players() -> Array[Player]:

	var active_players : Array[Player] = []

	for player in players:
		active_players.append(player)
	#print(active_players)
	return active_players


func add_player(player_name:String) -> Player:
	var p = Player.new()
	p.player_name = player_name
	players.append(p)
	add_child(p)
	return p

func start_game(map_name : String, player_settings : Array[PresetPlayer]):
	var map_data: DataWorldMap = load(CFG.WORLD_MAPS_PATH + map_name)
	var new_players = player_settings.map( func (setting) : return setting.create_player() )
	players.assign(new_players)
	WM.start_world(map_data)

#endregion


#region Gameplay UI

func switch_camera():
	## TODO implement actual camera switches
	if current_camera_position == CameraPosition.WORLD:
		current_camera_position = CameraPosition.BATTLE
	else:
		current_camera_position = CameraPosition.WORLD

func go_to_main_menu():
	draw_mode = false
	WM.close_world()
	BM.close_battle()
	UI.go_to_main_menu()

func show_in_game_menu():
	set_game_paused(true)
	UI.show_in_game_menu()

func hide_in_game_menu():
	UI.hide_in_game_menu()
	set_game_paused(false)

#endregion


#region Network

func set_default_game_setup_info() -> void:
	game_setup_info = GameSetupInfo.create_empty(4)


# endregion



#region Technical
# not gameplay

func is_game_paused():
	return get_tree().paused


func set_game_paused(is_paused : bool):
	print("pause = ",is_paused)
	get_tree().paused = is_paused


func quit_game():
	get_tree().quit()


## NOTE: fullscreen uses old style exclusive fullscreen because of Godot bug
func toggle_fullscreen():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		# DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		# TODO: change to borderless when Godot bug is fixed
		# https://github.com/godotengine/godot/issues/63500
		# there is a grey border around the screen
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

#endregion


#region Debug

## Toggle of default godot Debug tool - visible collision shapes
func toggle_collision_debug():

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

#endregion
