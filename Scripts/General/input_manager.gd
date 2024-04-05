# Singleton - IM

extends Node


"""
when player selects a hex it inform input_manager

there input_manager check who the current play is:
	1 in single player its simple check if its the player turn
	2 in multi player we check if its the local machine turn, if it is then it sends the move to all users

if the AI plays the move:
	1 in single player AI gets called to act when its their turn so it goes straight to gameplay
	2 in multi GAME HOST only sends the call to AI for it to make a move 


where do we call AI?

there is an end turn function "switch player" it could call the input manager to let it now who the current player is


"""
var timer = 0

var players : Array[Player] = []

var draw_mode : bool = false


enum camera_position {WORLD, BATTLE}
var current_camera_position = camera_position.WORLD


var raging_battle : bool

#region Game setup

func get_active_players() -> Array[Player]:

	var active_players : Array[Player] = []

	for player in players:
		if player.player_type != E.player_type.OBSERVER:
			active_players.append(player)
	#print(active_players)
	return active_players


#endregion


func switch_camera():
	if current_camera_position == camera_position.WORLD:
		current_camera_position = camera_position.BATTLE
		pass
	else:
		current_camera_position = camera_position.WORLD
		pass



func grid_input_listener(cord : Vector2i):
	#print("tile ",cord)
	#if WM.current_player.bot_engine != null:
	#    return # its a bot turn
	if draw_mode:
		get_node("/root/MainScene/DrawMenu").grid_input(cord)
		return
	
	if raging_battle:
		BM.grid_input(cord)
	else:
		WM.grid_input(cord)
	

func go_to_main_menu():
	draw_mode = false

	get_node("/root/MainScene/DrawMenu").hide_draw_menu()

	WM.close_world()
	BM.close_battle()
	get_node("/root/MainScene/MainMenu").toggle_menu_visibility()


func _physics_process(_delta):
	#func _process(_delta):
	timer += 1
	
	if Input.is_action_just_pressed("KEY_BOT_SPEED_SLOW"):
		BUS.animation_speed = BUS.animation_speed_values.NORMAL
		BUS.BotSpeed = BUS.bot_speed_values.FREEZE # 0 sec
	elif Input.is_action_just_pressed("KEY_BOT_SPEED_MEDIUM"):
		BUS.animation_speed = BUS.animation_speed_values.NORMAL
		BUS.BotSpeed = BUS.bot_speed_values.NORMAL # 0.5 sec
	elif Input.is_action_just_pressed("KEY_BOT_SPEED_FAST"):
		BUS.animation_speed = BUS.animation_speed_values.INSTANT
		
		BUS.BotSpeed = BUS.bot_speed_values.FAST # 1/60 sec
	
	# 60FPS -> timer=60 1 sec


func server_connection() -> bool:
	return false

func multiplayer_send():
	# CLIENT -> server
	if not server_connection:
		return
	
	pass


func multiplayer_receive():
	# client -> SERVER 
	pass


func multiplayer_broadcast_send():
	# SERVER -> clients
	pass

func multiplayer_broadcast_receive():
	# server -> CLIENT 
	pass
