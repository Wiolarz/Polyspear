class_name GameSetupInfo
extends RefCounted
# not a resource because we refer to players, sessions and other temporary
# things

class Slot extends RefCounted: # check if this is good base
	var occupier = 0 # "" -- we, name -- player with that name, int -- level of
					 # computer
	var faction : DataFaction = null
	var color : int = 0 # index of color in input manager
	var army_set : ArmySet = null # unused in scenario


var slots : Array[Slot]
var battle_map : DataBattleMap # used only in battle game
var world_map : DataWorldMap # used only in full scenario game
