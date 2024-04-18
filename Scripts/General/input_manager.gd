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

var _players : Array[Player] = []
var players : Array[Player] : 
	get: 
		return _players
	set(value):
		for p in _players:
			print("removing child")
			remove_child(p)
		for p in value:
			print("adding child")
			add_child(p)
		_players = value

var draw_mode : bool = false


enum camera_position {WORLD, BATTLE}
var current_camera_position = camera_position.WORLD


var raging_battle : bool


const default_usernames : Array[String] = [
	"Zdzichu",
	"Mag",
	"Gołąb",
	"Polygończyk",
	"Przemek",
	"Czarodziej",
	"Student",
	"Stary",
	"Cebularz",
	"DJ Skwarka",
	"Książę żab Marcin",
	"Gracz Doty",
]


const team_colors : Array[Dictionary] = [
	{ "name": "red", "color": Color(1.0, 0.0, 0.0) },
	{ "name": "blue", "color": Color(0.0, 0.4, 1.0) },
	{ "name": "green", "color": Color(0.0, 0.9, 0.0) },
	{ "name": "yellow", "color": Color(0.9, 0.8, 0.0) },
	{ "name": "purple", "color": Color(0.9, 0.2, 0.85) },
	{ "name": "orange", "color": Color(0.9, 0.5, 0.0) },
]


func get_team_color_at(index : int) -> Color:
	if not index in range(team_colors.size()):
		return Color(0.5, 0.5, 0.5, 1.0)
	return team_colors[index]["color"]


var chat_log : String

#region Game setup

# this probably should go somewhere else, but for now i don't know where to
# place it
var game_setup_info : GameSetupInfo


func set_default_game_setup_info() -> void:
	const slot_count : int = 4
	game_setup_info = GameSetupInfo.new()
	game_setup_info.slots.resize(slot_count)
	for i in range(slot_count):
		game_setup_info.slots[i] = GameSetupInfo.Slot.new()
		game_setup_info.slots[i].occupier = 0
		game_setup_info.slots[i].faction = WIP_factions[0]
		game_setup_info.slots[i].color = i


@export var WIP_factions : Array[Faction] = [
	preload("res://Resources/World/Factions/elf.tres"),
	preload("res://Resources/World/Factions/orc.tres"),
] # TODO choose a better place for this xD


func get_active_players() -> Array[Player]:

	var active_players : Array[Player] = []

	for player in players:
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

func grid_smooth_input_listener(coord : Vector2i):
	if draw_mode:
		get_node("/root/MainScene/MapEditor").grid_input(coord)


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
	

func go_to_main_menu():
	draw_mode = false

	get_node("/root/MainScene/MapEditor").hide_draw_menu()

	WM.close_world()
	BM.close_battle()
	get_node("/root/MainScene/MainMenu").toggle_menu_visibility()

func show_in_game_menu():
	# TODO: refactor UI
	$"/root/MainScene/GameMenu/Menu"._toggle_menu_status()


func make_server():
	var node = get_node_or_null("TheServer")
	if node != null:
		return
	var client = get_node_or_null("TheClient")
	if client:
		client.close()
		client.queue_free()
		remove_child(client)
	node = Server.new()
	node.name = "TheServer"
	add_child(node)


func make_client() -> void:
	var node = get_node_or_null("TheClient")
	if node != null:
		return
	var server = get_node_or_null("TheServer")
	if server:
		server.close()
		server.queue_free()
		remove_child(server)
	node = Client.new()
	node.name = "TheClient"
	add_child(node)


func server_listen(address : String, port : int, username : String):
	make_server()
	get_server().listen(address, port, username)


func server_close():
	if not get_server():
		return
	get_server().close()


func server_kick_all():
	if not get_server():
		return
	get_server().kick_all()


func client_connect_and_login(address : String, port : int, username : String):
	make_client()
	get_client().connect_to_server(address, port)
	get_client().queue_login(username)


func client_logout_and_disconnect():
	if not get_client():
		return
	get_client().logout_if_needed()
	get_client().close()

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


func get_server() -> Server:
	var server = get_node_or_null("TheServer")
	if server is Server:
		return server
	return null


func get_client() -> Client:
	var client = get_node_or_null("TheClient")
	if client is Client:
		return client
	return null


func server_connection() -> bool:
	return get_server() and get_server().enet_network


func client_connection() -> bool:
	return get_client() and get_client().enet_network


func get_current_name() -> String: # TODO rename to get_current_username
	if server_connection():
		return get_server().server_username
	return "(( you ))"


func send_chat_message(message : String) -> void:
	var server = get_server()
	var client = get_client()
	if not client:
		append_message_to_local_chat_log(message, get_current_name())
	if server:
		server.broadcast_say(message)
	elif client:
		client.queue_say(message)


func append_message_to_local_chat_log(message : String, \
		author : String) -> void:
	append_to_local_chat_log("%s: %s" % [ author, message ])


func append_to_local_chat_log(line : String) -> void:
	chat_log += line + '\n'


func clear_local_chat_log() -> void:
	chat_log = ""


func multiplayer_send(movement : MoveInfo):
	# CLIENT -> server
	var client : Client = get_client()
	if not client:
		return
	client.queue_movement(movement)


func multiplayer_receive():
	# client -> SERVER 
	pass


func multiplayer_broadcast_send(movement : MoveInfo):
	# SERVER -> clients
	var server : Server = get_server()
	if not server:
		return
	server.broadcast_movement(movement)

func multiplayer_broadcast_receive():
	# server -> CLIENT 
	pass


func get_random_username() -> String:
	return default_usernames[randi() % default_usernames.size()]
