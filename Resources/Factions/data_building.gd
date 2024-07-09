class_name DataBuilding
extends Resource

@export var name : String

@export var cost : Goods

@export var requirements : Array[DataBuilding]

@export var outpost_requirement : String


func is_outpost_upgrade() -> bool:
	return outpost_requirement != ""


static func get_network_id(building : DataBuilding) -> String:
	if not building:
		return ""
	assert(building.resource_path.begins_with(CFG.BUILDINGS_PATH), \
			"building serialization not supported")
	return building.resource_path.trim_prefix(CFG.BUILDINGS_PATH)


static func from_network_id(network_id : String) -> DataBuilding:
	if network_id.is_empty():
		return null
	print("loading DataBuilding - %s/%s" % \
		[ CFG.BUILDINGS_PATH, network_id ])
	return load("%s/%s" % [ CFG.BUILDINGS_PATH, network_id ]) as DataBuilding
