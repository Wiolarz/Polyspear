class_name Deposit
extends Place

var accumulated_goods : Goods
var per_turn : Goods


func _init(start : Goods, gain_per_turn : Goods):
	accumulated_goods = start.duplicate()
	per_turn = gain_per_turn.duplicate()


func interact(_world_state : WorldState, army : Army) -> void:
	collect(army.controller)


func on_end_of_turn(_world_state : WorldState) -> void:
	accumulated_goods.add(per_turn)


func get_map_description() -> String:
	return accumulated_goods.to_string_short("empty")


func collect(player : Player):
	player.goods.add(accumulated_goods)
	accumulated_goods.clear()
