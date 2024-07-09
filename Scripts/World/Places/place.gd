class_name Place
extends RefCounted # RefCounted is default

signal controller_changed()

# TODO make this not duplicated
const PATH_TODO_MOVE_TO_CONFIG = "res://Scripts/World/Places/"

# TODO make controller private and set proper getter and setter
var controller_index : int = -1
var defender_army : Army
var coord : Vector2i
var movable : bool = false

## used only in basic places which are not derived classes
var basic_type : String


static func create_basic(coord : Vector2i, movable : bool, type_name : String) \
		-> Place:
	var place := Place.new()
	place.coord = coord
	place.movable = movable
	place.basic_type = type_name
	return place


static func create_new(_args : PackedStringArray, coord : Vector2i) -> Place:
	# TODO add grid to args -- it would ge great also to add hex *atomically*
	# in this funciton
	var place := Place.new()
	place.coord = coord
	return place


func get_army_at_start() -> PresetArmy:
	return null


func interact(_world_state : WorldState, army : Army) -> bool:
	print(army)
	return false


func on_end_of_turn(_world_state : WorldState) -> void:
	pass


func get_map_description() -> String:
	return ""


func capture(_world_state : WorldState, _player_index : int) -> bool:
	return false


# func change_controler(player : Player):
# 	controller = player
# 	controller_changed.emit()


static func get_network_serializable(place : Place, \
		world_state : WorldState) -> Dictionary:
	if not place:
		return {}
	var dict : Dictionary = {}
	place.to_specific_serializable(dict)
	dict["type"] = place.get_type()
	dict["player"] = place.controller_index
	return dict


static func from_network_serializable(dict : Dictionary, coord : Vector2i) -> Place:
	var type = dict["type"]
	var script_path = "%s/%s.gd" % [ PATH_TODO_MOVE_TO_CONFIG, type[0] ]
	var script = load(script_path) as Script
	assert(script)
	var place : Place = script.create_new(PackedStringArray(), coord)
	var player_index = dict["player"]
	place.controller_index = player_index
	place.paste_specific_serializable_state(dict)
	return place


func get_image_override() -> Resource:
	return null


func get_type() -> String:
	if get_script() != Place:
		return get_script().resource_path.get_file().get_basename()
	else:
		return basic_type




## should be overridden by each place
## This function has to copy such information of state that it would be
## possible to add it to the state after "create_new" call
func to_specific_serializable(dict : Dictionary) -> void:
	pass


## shoould be overridden by each place
## This function has to recover every information that is not recovered by
## "create_new" of the type with defaults and changing player which is done
## earlier
func paste_specific_serializable_state(dict : Dictionary) -> void:
	return
