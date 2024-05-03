class_name GameSetupInfo
extends RefCounted

## Game Setup in the lobby, currently used only in multiplayer [br]
## Map chosen, info on game slots setup (factions, colors, etc) [br]
## TODO: start using in single player [br]
## TODO: synch slot count etc with map when changing maps [br]
## WARNING not a resource because we refer to players, sessions
## and other temporary objects that should not be saved

enum GameMode {
	UNKNOWN, ## forces to initialize
	WORLD, ## full map with heroes and economy
	BATTLE, ## single battle only, no economy
	MAP_EDITOR, ## special mode only for map editing
}

var game_mode : GameMode = GameMode.WORLD
var world_map : DataWorldMap ## used only in full world mode
var battle_map : DataBattleMap ## used only in battle mode
var slots : Array[Slot] ## slot for each player color on the map picked

func is_in_mode_world():
	return game_mode == GameMode.WORLD

func is_in_mode_battle():
	return game_mode == GameMode.BATTLE


func to_dictionary(local_username : String = "") -> Dictionary:
	var result = {
		"game_mode": game_mode_to_str(),
		"world_map": DataWorldMap.get_network_id(world_map),
		"battle_map": DataBattleMap.get_network_id(battle_map),
		"slots": [],
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
	if "game_mode" in dict and dict["game_mode"] is String:
		result.game_mode = GameSetupInfo.game_mode_from_str(dict["game_mode"])
	if "world_map" in dict and dict["world_map"] is String:
		result.world_map = DataWorldMap.from_network_id(dict["world_map"])
	if "battle_map" in dict and dict["battle_map"] is String:
		result.battle_map = DataBattleMap.from_network_id(dict["battle_map"])
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


func game_mode_to_str() -> String:
	return GameMode.keys()[game_mode].to_lower()


static func game_mode_from_str(mode_as_str : String) -> GameMode:
	mode_as_str = mode_as_str.to_lower()
	for mode in GameMode.keys():
		if mode.to_lower() == mode_as_str:
			return GameMode[mode]
	push_error("Unknown game mode: \"%s\"" % mode_as_str)
	return GameMode.UNKNOWN


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


static func create_empty(slot_count : int) -> GameSetupInfo:
	var result = GameSetupInfo.new()
	result.slots.resize(slot_count)
	for i in range(slot_count):
		result.slots[i] = GameSetupInfo.Slot.new()
		result.slots[i].occupier = 0
		result.slots[i].faction = CFG.FACTIONS_LIST[0]
		result.slots[i].color = i
	return result


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
