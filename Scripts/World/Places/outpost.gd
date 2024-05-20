class_name Outpost
extends Place


var per_turn : Goods
var outpost_type : String


func _init(gain_per_turn : Goods, outpost_type_ : String):
	per_turn = gain_per_turn.duplicate()
	outpost_type = outpost_type_


func interact(army : ArmyForm):
	_take_control(army.controller)


func on_end_of_turn():
	if controller:
		controller.goods.add(per_turn)


func get_map_description() -> String:
	return per_turn.to_string_short("empty")


func _take_control(player : Player):
	if controller:
		controller.outpost_remove(self)
	
	change_controler(player)

	player.outpost_add(self)

	
