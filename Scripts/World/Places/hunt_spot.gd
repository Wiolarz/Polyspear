class_name HuntSpot
extends Place

## Hunt Spot starts with the lvl 1 army present on top of it
##
##

const wood_materials = [[3,0,0], [6,0,0], [9,0,0]]
const iron_materials = [[0,3,0], [0,6,0], [0,9,0]]
const ruby_materials = [[0,0,3], [0,0,6], [0,0,9]]

## Setup Variables
var neutral_armies : Array[PresetArmy]
var material_rewards : Array[Goods] = []
var army_respawn_time : int = 1 # in turns
var hunt_spot_type : String

## used to check if new army should respawn
var spawned_army : Army

## local variables
var current_level : int = 0
var _present_goods : Goods
var _time_left_for_respawn : int = 0


# func _init(units_sets_folder : String, new_material_rewards : Array[Goods]):
# 	print("hunt spot created")
# 	neutral_armies = HuntSpot.get_hunt_army_presets(units_sets_folder)
# 	material_rewards = new_material_rewards

# 	# TODO verify if there is a need of a deep copy?
# 	_present_goods = material_rewards[0].duplicate()


static func create_place(coord_ : Vector2i, args : PackedStringArray) -> Place:
	# if args.size() != 1:
	# 	push_error("hunt spot needs exactly one argument to create")
	var result := HuntSpot.new()

	var type : String = args[0] if args.size() >= 1 else "wood"
	if not result._set_type(type):
		return null

	# TODO move this somewhere else -- this should not be here
	result.coord = coord_
	result.current_level = 0
	result.movable = true
	result._time_left_for_respawn = 0

	return result


func _set_type(type : String) -> bool:
	var rewards : Array = []
	match type:
		"wood":
			neutral_armies = \
				HuntSpot.get_hunt_army_presets(CFG.HUNT_WOOD_PATH)
			rewards = wood_materials
		"iron":
			neutral_armies = \
				HuntSpot.get_hunt_army_presets(CFG.HUNT_IRON_PATH)
			rewards = iron_materials
		"ruby":
			neutral_armies = \
				HuntSpot.get_hunt_army_presets(CFG.HUNT_RUBY_PATH)
			rewards = ruby_materials
		_:
			push_error("bad type of hunt spot")
			return false

	for reward in rewards:
		material_rewards.append(Goods.from_array(reward))
	_present_goods = material_rewards[current_level]
	hunt_spot_type = type

	return true


func get_army_at_start() -> PresetArmy:
	assert(neutral_armies.size() > 0, "Hunt Spot Resource Setup incorrectly")
	return neutral_armies[0]
	


func interact(army : Army) -> void:
	collect(army.faction)


func on_end_of_round(world_state : WorldState = null):
	if spawned_army: # neutral army is alive
		return
	if _time_left_for_respawn == 0:
		#  army was killed this turn -> start of respawn timer
		_time_left_for_respawn = army_respawn_time
		return
	if _time_left_for_respawn == 1: # respawn timer finished
		try_respawn(world_state)
		return
	_time_left_for_respawn -= 1


func try_respawn(world_state : WorldState):
	if world_state.get_army_at(coord):
		print("respawn failed @ ", coord)
		return
	if current_level < neutral_armies.size()-1:
		current_level += 1
	world_state.spawn_army_from_preset(neutral_armies[current_level], coord, \
		-1)
	_present_goods = material_rewards[current_level].duplicate()


func get_map_description() -> String:
	return _present_goods.to_string_short("empty")


func collect(faction : Faction) -> void:
	# TODO change it so the resources are gathered from number of killed units,
	# so even if the player looses he still can get some resource
	faction.add_goods(_present_goods)
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
	dict["hunt_spot_type"] = hunt_spot_type


func paste_specific_serializable(dict : Dictionary) -> void:
	_set_type(dict["hunt_spot_type"])
	current_level = dict["current_level"]
	_present_goods = Goods.from_array(dict["present_goods"])
	_time_left_for_respawn = dict["time_left_for_respawn"]
