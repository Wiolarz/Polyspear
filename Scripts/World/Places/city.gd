class_name City
extends Place


var buildings : Array[DataBuilding] = []


func _init():
	type = E.WorldMapTiles.CITY


func get_heroes_to_buy() -> Array[DataHero]:
	var result : Array[DataHero] = []
	for hero_data : DataHero in controller.faction.heroes:
		result.append(hero_data)
	return result


func get_units_to_buy() -> Array[DataUnit]:
	var units : Array[DataUnit] = []
	for unit_data : DataUnit in controller.faction.units_data:
		units.append(unit_data)
	return units


func build(building : DataBuilding):
	if not can_build(building):
		return
	if controller.purchase(building.cost):
		buildings.append(building)


func has_build(building : DataBuilding):
	return building in buildings


func can_build(building : DataBuilding):
	if has_build(building):
		return false
	if not controller.has_enough(building.cost):
		return false
	return building.requirements \
		.all(func b_present(b:DataBuilding): return has_build(b))
