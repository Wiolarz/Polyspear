class_name DataBuilding
extends Resource

@export var name : String

@export var cost : Goods

@export var requirements : Array[DataBuilding]

@export var discount_counter : int = 0

## if a resource type is stated it means this is a special faction wide construction
@export var outpost_requirement : String


func clone() -> DataBuilding:
	var new_building = DataBuilding.new()
	new_building.name = name
	new_building.cost = cost.duplicate()
	new_building.requirements = requirements.duplicate()
	new_building.outpost_requirement = outpost_requirement
	return new_building

func is_outpost_building() -> bool:
	return outpost_requirement != ""

func increase_discount_counter() -> void:
	discount_counter += 1

func reset_discount_counter() -> void:
	discount_counter = 0

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
