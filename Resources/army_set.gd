class_name ArmySet

extends Resource


@export var units : Array[PackedScene]

@export var hero : PackedScene = null


func create_army() -> Army:
	var new_army = Army.new()
	new_army.unit_scenes = units
	new_army.hero = hero
	return new_army