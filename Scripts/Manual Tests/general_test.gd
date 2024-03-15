class_name GeneralTest

extends Node

@export var world_setup : WorldSetup
@export var test_battle_setup : BattleSetup


func test_battle() -> bool:
	"""
	Returns true if the test started succesfully
	"""

	if test_battle_setup == null:
		print("No battle setup")
		return false

	var players : Array[Player] = []
	for player_set in test_battle_setup.player_settings:
		var player = player_set.generate_player()
		players.append(player)
	IM.players = players

	
	var new_armies : Array[Army] = []
	for i in range(test_battle_setup.armies.size()):
		var new_army = test_battle_setup.armies[i].generate_army()
		new_army.controller = players[i]
		new_armies.append(new_army)

	BM.start_battle(new_armies, test_battle_setup.battle_map)

	return true