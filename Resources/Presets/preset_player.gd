class_name  PresetPlayer
extends Resource

"""
test data for Input Manager
"""

@export var faction : DataFaction
@export var player_type : E.PlayerType = E.PlayerType.OBSERVER
@export var player_name : String
@export var starting_goods : Goods


func create_player() -> Player:
	var new_player = Player.new()
	new_player.faction = faction
	new_player.player_name = player_name
	new_player.goods = starting_goods.duplicate()
	return new_player
