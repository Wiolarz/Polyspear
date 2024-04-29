class_name GameSetupInfo
extends RefCounted

## Game Setup in the lobby, currently used only in multiplayer [br]
## Map chosen, info on game slots setup (factions, colors, etc) [br]
## TODO: start using in single player [br]
## TODO: synch slot count etc with map when changing maps [br]
## WARNING not a resource because we refer to players, sessions
## and other temporary objects that should not be saved

# var mode_is_battle : bool = false
# var battle_map : DataBattleMap # used only in battle game
var world_map : DataWorldMap # used only in full world game
var slots : Array[Slot]


func to_dictionary(local_username : String = "") -> Dictionary:
	var result = {
		"slots": [],
		"world_map": DataWorldMap.get_network_id(world_map),
	}
	for slot in slots:
		result["slots"].append({
			"occupier": GameSetupInfo.occupier_prepare_for_network( \
					slot.occupier, local_username),
			"faction": slot.faction.get_network_id(),
			"color": slot.color,
		})
	return result

static func from_dictionary(dict : Dictionary, \
		local_username : String = "") -> GameSetupInfo:
	var result = GameSetupInfo.new()
	if "world_map" in dict and dict["world_map"] is String:
		result.world_map = DataWorldMap.from_network_id(dict["world_map"])
	if "slots" in dict and dict["slots"] is Array:
		for read_slot in dict["slots"]:
			var new_slot : Slot = Slot.new()
			if "occupier" in read_slot:
				new_slot.occupier = occupier_receive_from_network( \
					read_slot["occupier"], local_username)
			if "faction" in read_slot and read_slot["faction"] is String:
				new_slot.faction = \
					DataFaction.from_network_id(read_slot["faction"])
			if "color" in read_slot and read_slot["color"] is int:
				new_slot.color = read_slot["color"]
			result.slots.append(new_slot)
	return result


static func occupier_prepare_for_network(occupier, local_username : String):
	if occupier is String and occupier == "":
		return local_username
	return occupier


static func occupier_receive_from_network(occupier, local_username : String):
	if occupier is String and occupier == local_username:
		return ""
	if occupier is String or occupier is int:
		return occupier
	push_error("invalid occupier received ", occupier)


## Info for a single slot
class Slot extends RefCounted: # check if this is good base

	## occupier identifies who uses this slot [br]
	## its an `int` or a `String` [br]
	## `String == ""` -> we (local player) [br]
	## `String != ""` -> remote player with specified network name [br]
	## `int` -> AI level eg. 1
	var occupier = 0

	## index of color see `CFG.TEAM_COLORS`
	var color : int = 0

	var faction : DataFaction = null

	## TODO: add army setup for single battle
