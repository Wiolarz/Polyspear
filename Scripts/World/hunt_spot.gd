class_name HuntSpot
extends Place

var neutral_armies : Array[PresetArmy]
var accumulated_goods : Goods
var per_turn : Goods

func _init(units_sets_folder : String):
	# TODO verify if there is a need of a deep copy?
	neutral_armies = HuntSpot.get_hunt_army_presets(units_sets_folder)


func interact(army : ArmyForm):
	collect(army.controller)

func on_end_of_turn():
	accumulated_goods.add(per_turn)

func get_map_description() -> String:
	return accumulated_goods.to_string_short("empty")

func collect(player : Player):
	player.goods.add(accumulated_goods)
	accumulated_goods.clear()



static func get_hunt_army_presets(folder_path : String) -> Array[PresetArmy]:
	var armies : Array[PresetArmy] = []

	var files = TestTools.list_files_in_folder(folder_path, true)
	for file in files:
		armies.append(load(file))

	return armies
