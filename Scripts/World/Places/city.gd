class_name City
extends Place


var buildings : Array[DataBuilding] = []


func _init():
	type = E.WorldMapTiles.CITY


func get_heroes_to_buy() -> Array[DataHero]:
	var result : Array[DataHero] = []
	for hero_data : DataHero in controller.get_faction().heroes:
		result.append(hero_data)
	return result


func get_cost_description(hero: DataHero) -> String:
	if controller.has_hero(hero):
		return "✔"
	var cost_string = str(controller.get_hero_cost(hero))
	if controller.has_dead_hero(hero):
		return "Ressurect\n" + cost_string
	return cost_string


func can_buy_hero(hero: DataHero) -> bool:
	if controller.has_hero(hero):
		return false
	if W_GRID.get_army(coord):
		return false
	var cost = controller.get_hero_cost(hero)
	return controller.has_enough(cost)


func get_units_to_buy() -> Array[DataUnit]:
	var units : Array[DataUnit] = []
	for unit_data : DataUnit in controller.get_faction().units_data:
		units.append(unit_data)
	return units


func can_buy_unit(unit: DataUnit, hero_army : ArmyForm) -> bool:
	if not hero_army:
		return false
	if hero_army.entity.units_data.size() > hero_army.entity.hero.max_army_size:
		return false
	if not unit_has_required_building(unit):
		return false
	return controller.has_enough(unit.cost)


func unit_has_required_building(unit : DataUnit) -> bool:
	if not unit.required_building:
		return true
	return has_built(unit.required_building)


func build(building : DataBuilding) -> void:
	if not can_build(building):
		return
	if controller.purchase(building.cost):
		if building.outpost_requirement == "":
			buildings.append(building)
		else:
			controller.outpost_buildings.append(building)


func has_built(building : DataBuilding) -> bool:
	return building in buildings or building in controller.outpost_buildings


func can_build(building : DataBuilding)-> bool:
	if has_built(building):
		return false
	if not controller.has_enough(building.cost):
		return false
	
	if not controller.outpost_requirement(building.outpost_requirement):
		return false

	return building.requirements \
		.all(func b_present(b:DataBuilding): return has_built(b))
