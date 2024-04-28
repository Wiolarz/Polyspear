class_name GameSetupInfo
extends RefCounted
# not a resource because we refer to players, sessions and other temporary
# things

class Slot extends RefCounted: # check if this is good base

	## identifies who used this slot
	## int or String
	## String == "" -> we (local player)
	## String != "" -> remote player
	## int -> AI level eg. 1
	var occupier = 0

	var faction : DataFaction = null
	var color : int = 0 # index of color in input manager
	var army_set : PresetArmy = null # unused in scenario


var slots : Array[Slot]
# var battle_map : DataBattleMap # used only in battle game
var world_map : DataWorldMap # used only in full world game


func to_dictionary(local_username : String = "") -> Dictionary:
	var result = {
		"slots": [],
		"world_map": world_map.get_netword_id(),
	}
	for slot in slots:
		result["slots"].append({
			"occupier": \
				occupier_prepare_for_network(slot.occupier, local_username),
			"faction": slot.faction.get_netword_id(),
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
	return local_username if (occupier is String and occupier == "") \
		else occupier

static func occupier_receive_from_network(occupier, local_username : String):
	if occupier is String and occupier == local_username:
		return ""
	elif occupier is String or occupier is int:
		return occupier
