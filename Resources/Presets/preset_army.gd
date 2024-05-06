class_name PresetArmy

extends Resource


@export var units : Array[DataUnit]

@export var hero : PackedScene = null # TODO create a presethero resource




static func from_units_data(unitData : Array[DataUnit]) -> PresetArmy:
	var result = PresetArmy.new()
	result.units = unitData
	return result
