class_name ArmySet

extends Resource


@export var Units : Array[PackedScene]

@export var hero : PackedScene = null


func generate_army() -> Army:
	var new_army = Army.new()
	new_army.Units = Units
	new_army.hero = hero
	return new_army