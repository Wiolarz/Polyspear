class_name ArmySet

extends Resource


@export var units : Array[DataUnit]

@export var hero : PackedScene = null


func create_army() -> Army:
	var new_army = Army.new()
	new_army.units_data = units
	new_army.hero = hero
	return new_army

static func from_units_data(unitData : Array[DataUnit]):
	var result = ArmySet.new()
	result.units = unitData
	return result
	
