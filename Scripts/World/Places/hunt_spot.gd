class_name HuntSpot
extends Place

## Hunt Spot starts with the lvl 1 army present on top of it
##
##

## Setup Variables
var neutral_armies : Array[PresetArmy]
var material_rewards : Array[Goods]
var army_respawn_timer : int = 1 # in turns

## local variables
var _present_goods : Goods

var current_level : int = 0:
	get:
		return current_level
	set(new_var):
		if new_var < 0 or new_var >= neutral_armies.size():
			printerr("hunt spot: attempt to assign incorrect level value: " + str(new_var))
			return
		current_level = new_var

var _alive_army : ArmyForm
var _time_left_for_respawn : int = 0


func _init(units_sets_folder : String, new_material_rewards : Array[Goods]):
	print("hunt spot created")
	neutral_armies = HuntSpot.get_hunt_army_presets(units_sets_folder)
	material_rewards = new_material_rewards

	# TODO verify if there is a need of a deep copy?
	_present_goods = material_rewards[0].duplicate()


func on_game_started():
	_alive_army = WM.spawn_neutral_army(neutral_armies[0], coord)


func interact(army : ArmyForm):
	collect(army.controller)


func on_end_of_turn():
	if _alive_army != null: # neutral army is dead
		return
	if _time_left_for_respawn == 0:
		#  army was killed this turn -> start of respawn timer
		_time_left_for_respawn = army_respawn_timer
		return
	if _time_left_for_respawn == 1: # respawn timer finished
		try_respawn()
		return
	_time_left_for_respawn -= 1


func try_respawn():
	if W_GRID.get_army(coord):
		print("respawn failed @ ", coord)
		return
	if current_level < neutral_armies.size()-1:
		current_level += 1
	_alive_army = WM.spawn_neutral_army(neutral_armies[current_level], coord)
	_present_goods = material_rewards[current_level].duplicate()


func get_map_description() -> String:
	return _present_goods.to_string_short("empty")


func collect(player : Player):
	player.goods.add(_present_goods)
	_present_goods.clear()


static func get_hunt_army_presets(folder_path : String) -> Array[PresetArmy]:
	var armies : Array[PresetArmy] = []

	var files = FileSystemHelpers.list_files_in_folder(folder_path, true)
	for file in files:
		armies.append(load(file))

	return armies


func to_specific_serializable(dict : Dictionary) -> void:
	dict["present_goods"] = _present_goods.to_array()
	dict["current_level"] = current_level
	# "alive_army" not needed -- deduced
	dict["time_to_respawn"] = _time_left_for_respawn
