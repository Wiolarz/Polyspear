class_name DataBuilding
extends Resource

@export var name : String

@export var cost : Goods

@export var requirements : Array[DataBuilding]

@export var discounts = [] as Array[Discount]


## if a resource type is stated it means this is a special faction wide construction
@export var outpost_requirement : String

func apply_discounts(price : Goods) -> Goods:
	if not discounts or discounts.is_empty():
		return price
	for discount in discounts:
		price = discount.apply_discount(price)
	return price

func reset_discounts() -> void:
	for discount in discounts:
		discount.reset_discount_counter()

func is_outpost_building() -> bool:
	return outpost_requirement != ""

func on_end_of_round() -> void:
	if not discounts or discounts.is_empty():
		return
	for discount in discounts:
		discount.on_end_of_round()

func clone() -> DataBuilding:
	var new_building = DataBuilding.new()
	new_building.name = name
	new_building.cost = cost.duplicate()
	new_building.requirements = requirements.duplicate()
	new_building.outpost_requirement = outpost_requirement
	new_building.discounts = []
	for discount in discounts:
		new_building.discounts.append(discount.copy())
	return new_building

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
