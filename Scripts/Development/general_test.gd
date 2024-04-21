class_name GeneralTest

extends Node

@export var world_setup : PresetWorld
@export var test_battle_setup : PresetBattle


func set_players(players : Array[PresetPlayer]):
	var new_players : Array[Player] = []
	for player_set in test_battle_setup.player_settings:
			var new_player = player_set.create_player()
			new_players.append(new_player)
	IM.players = new_players


func test_battle() -> void:
	assert(test_battle_setup != null, "No battle setup")

	set_players(test_battle_setup.player_settings)

	var active_players = IM.get_active_players()
	var new_armies : Array[Army] = []
	for i in range(test_battle_setup.armies.size()):
		var new_army = test_battle_setup.armies[i].create_army()
		new_army.controller = active_players[i]
		new_armies.append(new_army)

	BM.start_battle(new_armies, test_battle_setup.battle_map)


func test_world() -> void:
	assert(world_setup != null, "No world setup")

	set_players(world_setup.player_settings)

	WM.start_world(world_setup.world_map)
