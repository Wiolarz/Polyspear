class_name DataFaction

extends Resource

"""
Complete Faction data:
	1 Placement of every tile type
	2 Info about assignment of every city
"""
@export var faction_name : String

## list of units avalaible in the battle lobby [br]
## should be a copy of the units offered by the buildings list
@export var units_data : Array[DataUnit]

@export var heroes : Array[DataHero]

@export var buildings : Array[DataBuilding]

func get_network_id() -> String:
	return resource_path


static func from_network_id(network_id : String) -> DataFaction:
	return load(network_id) as DataFaction


# no factory needed
