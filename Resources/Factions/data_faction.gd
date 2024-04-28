class_name DataFaction

extends Resource

"""
Complete Faction data:
	1 Placement of every tile type
	2 Info about assignment of every city
"""
@export var faction_name : String

@export var units_data : Array[DataUnit]

@export var heroes : Array # Hero_Data

@export var city : Resource # TODO City_Data

func get_network_id() -> String:
	return resource_path.get_file()

# no factory needed
