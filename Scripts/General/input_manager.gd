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

var game_setup_info : GameSetupInfo

var players : Array[Player] = [] :
	get:
		return players
	set(value):
		for p in players:
			print("removing player ", p)
			p.queue_free()
		for p in value:
			print("adding player ", p)
			p.name = "Player_"+p.player_name
			add_child(p)
		players = value

## flag for MAP EDITOR
var draw_mode : bool = false

func init_game_setup():
	game_setup_info = GameSetupInfo.create_empty(4)


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
	UI.ensure_camera_is_spawned()
	if game_setup_info.is_in_mode_world():
		_start_game_world()
		B_GRID.position.x = WM.get_bounds_global_position().end.x + CFG.MAPS_OFFSET_X
		UI.set_camera(E.CameraPosition.WORLD)
	if game_setup_info.is_in_mode_battle():
		_start_game_battle()
		UI.set_camera(E.CameraPosition.BATTLE)
	if NET.server:
		NET.server.broadcast_start_game()

func go_to_map_editor():
	UI.ensure_camera_is_spawned()
	draw_mode = true
	UI.go_to_map_editor()

func _start_game_world():
	var new_players : Array[Player] = []
	for player_preset in get_player_presets():
		new_players.append(player_preset.create_player())
	UI.go_to_main_menu()
	players = new_players
	WM.start_world(game_setup_info.world_map)


func get_player_presets() -> Array[PresetPlayer]:
	# TODO: drut, replace with reading game_setup_info
	var elf = PresetPlayer.new();
	elf.faction = CFG.FACTION_ELVES
	elf.player_name = "elf"
	elf.player_type =  E.PlayerType.HUMAN
	elf.starting_goods = CFG.get_start_goods()

	var orc = PresetPlayer.new()
	orc.faction = CFG.FACTION_ORCS
	orc.player_name = "orc"
	orc.player_type =  E.PlayerType.HUMAN
	orc.starting_goods = CFG.get_start_goods()

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


func go_to_main_menu():
	draw_mode = false
	BM.reset_grid_and_unit_forms()
	WM.close_world()
	UI.go_to_main_menu()


func toggle_in_game_menu():
	UI.toggle_in_game_menu()
	set_game_paused(UI.requests_pause())

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

#endregion
