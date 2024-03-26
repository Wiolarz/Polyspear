class_name GeneralTest

extends Node

@export var world_setup : WorldSetup
@export var test_battle_setup : BattleSetup


func set_players(players : Array[PlayerSetting]):
	var new_players : Array[Player] = []
	for player_set in test_battle_setup.player_settings:
			var new_player = player_set.create_player()
			new_players.append(new_player)
	IM.players = new_players


func test_battle() -> bool:
	"""
	Returns true if the test started succesfully
	"""

	if test_battle_setup == null:
		print("No battle setup")
		return false


	set_players(test_battle_setup.player_settings)
	
	var active_players = IM.get_active_players()
	var new_armies : Array[Army] = []
	for i in range(test_battle_setup.armies.size()):
		var new_army = test_battle_setup.armies[i].create_army()
		new_army.controller = active_players[i]
		new_armies.append(new_army)

	BM.start_battle(new_armies, test_battle_setup.battle_map)

	return true


func test_world() -> bool:
	"""
	Returns true if the test started succesfully
	"""

	if world_setup == null:
		print("No world setup")
		return false

	set_players(world_setup.player_settings)

	WM.start_world(world_setup.world_map)
	

	return true