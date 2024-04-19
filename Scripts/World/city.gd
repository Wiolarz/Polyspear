class_name City
extends Place


func _init():
	type = E.WorldMapTiles.CITY

func get_units_to_buy() -> Array[DataUnit]:
	var units : Array[DataUnit] = []
	for unit_data : DataUnit in controller.faction.units_data:
		units.append(unit_data)
	return units
