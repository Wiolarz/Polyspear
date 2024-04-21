class_name  PlayerSetting

extends Resource

"""
test data for Input Manager
"""

@export var faction : DataFaction
@export var player_type : E.player_type = E.player_type.OBSERVER
@export var player_name : String
@export var goods : Goods


func create_player() -> Player:
	var new_player = Player.new()
	new_player.faction = faction
	new_player.player_name = player_name
	new_player.goods = goods.duplicate()
	return new_player
