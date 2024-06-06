class_name Outpost
extends Place


var per_turn : Goods
var outpost_type : String

var neutral_army : PresetArmy


func _init(gain_per_turn : Goods, outpost_type_ : String, army_path : String):
	per_turn = gain_per_turn.duplicate()
	outpost_type = outpost_type_

	neutral_army = load(army_path)


func on_game_started():
	WM.spawn_neutral_army(neutral_army, coord)


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


func to_specific_serializable(dict : Dictionary) -> void:
	pass
