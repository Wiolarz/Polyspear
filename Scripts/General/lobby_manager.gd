# Singleton - LM

extends Node

var players : Array[Player] = []

var world_map : WorldMap


func add_player():
	var new_player = Player.new()
	players.append(new_player)


func basic_test_game_setup():
	pass



func start_game():
	pass