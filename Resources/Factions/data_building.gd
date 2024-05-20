class_name DataBuilding
extends Resource

@export var name : String

@export var cost : Goods

@export var requirements : Array[DataBuilding]

@export var outpost_requirement : String


# func get_network_id() -> String:
# 	return resource_path


# static func from_network_id(network_id : String) -> DataFaction:
# 	return load(network_id) as DataFaction
