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

var camera : PolyCamera

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
			p.name = "Player_"+p.player_name
			add_child(p)
		_players = value

## flag for MAP EDITOR
var draw_mode : bool = false

var raging_battle : bool

var current_camera_position = E.CameraPosition.WORLD

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
func _process(delta):
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

	if camera:
		camera.process_camera(delta)


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

func init_game_setup():
	game_setup_info = GameSetupInfo.create_empty(4)

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

## starts game based on game_setup_info
func start_game():
	if not camera:
		camera = PolyCamera.new()
		camera.name = "PolyCamera"
		add_child(camera)
	if game_setup_info.is_in_mode_world():
		_start_game_world()
		B_GRID.position.x = WM.get_bounds_global_position().end.x + CFG.MAPS_OFFSET_X
		set_camera(E.CameraPosition.WORLD)
	if game_setup_info.is_in_mode_battle():
		_start_game_battle()
		set_camera(E.CameraPosition.BATTLE)
	if NET.server:
		NET.server.broadcast_start_game()


func _start_game_world():
	var new_players = get_player_settings().map( func (setting) : return setting.create_player() )
	UI.go_to_main_menu()
	players.assign(new_players)
	WM.start_world(game_setup_info.world_map)


func get_player_settings() -> Array[PresetPlayer]:
	# TODO: drut, replace with reading game_setup_info
	var elf = PresetPlayer.new();
	elf.faction = CFG.FACTION_ELVES
	elf.player_name = "elf"
	elf.player_type =  E.PlayerType.HUMAN
	elf.goods = CFG.get_start_goods()

	var orc = PresetPlayer.new()
	orc.faction = CFG.FACTION_ORCS
	orc.player_name = "orc"
	orc.player_type =  E.PlayerType.HUMAN
	orc.goods = CFG.get_start_goods()

	return [ elf, orc ]


func _start_game_battle():
	var map_data = game_setup_info.battle_map
	var new_players : Array[Player] = []
	var armies : Array[Army] = []

	for player_idx in range(2):
		var player = create_player(player_idx)
		new_players.append(player)
		armies.append(create_army(player_idx, player))
	IM.players = new_players

	UI.go_to_main_menu()
	BM.start_battle(armies, map_data, 0)


func is_bot(player_idx : int) -> bool:
	return game_setup_info.is_bot(player_idx)


func create_army(player_idx : int, player : Player) -> Army:
	var army = Army.new()
	army.controller = player
	army.units_data = game_setup_info.get_units_data_for_battle(player_idx)
	return army


func create_player(player_idx : int) -> Player:
	if player_idx == 0:
		var elf = Player.new();
		elf.faction = CFG.FACTION_ELVES
		elf.player_name = "elf"
		elf.use_bot(is_bot(player_idx))
		elf.goods = CFG.get_start_goods()
		return elf

	var orc = Player.new()
	orc.faction = CFG.FACTION_ORCS
	orc.player_name = "orc"
	orc.use_bot(is_bot(player_idx))
	orc.goods = CFG.get_start_goods()
	return orc

#endregion


#region Gameplay UI

func switch_camera() -> void:
	if current_camera_position == E.CameraPosition.WORLD:
		if raging_battle:
			set_camera(E.CameraPosition.BATTLE)
	else:
		if game_setup_info.game_mode == GameSetupInfo.GameMode.WORLD:
			set_camera(E.CameraPosition.WORLD)


func set_camera(pos : E.CameraPosition) -> void:
	current_camera_position = pos
	if pos == E.CameraPosition.BATTLE:
		camera.set_bounds(BM.get_bounds_global_position())
	else :
		camera.set_bounds(WM.get_bounds_global_position())


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
