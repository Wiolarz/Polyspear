class_name City
extends Place


func _init():
	type = E.WorldMapTiles.CITY
	
func get_units_to_buy() -> Array[DataUnit]:
	if controller.faction.faction_name == "orc":
		return [
			load("res://Resources/Battle/Units/Orcs/orc_1_brute.tres"),
			load("res://Resources/Battle/Units/Orcs/orc_2_brigand.tres"),
			load("res://Resources/Battle/Units/Orcs/orc_3_champion.tres"),
		]

	return [
		load("res://Resources/Battle/Units/Elves/elf_1_spearmen.tres"),
		load("res://Resources/Battle/Units/Elves/elf_2_archer.tres"),
		load("res://Resources/Battle/Units/Elves/elf_3_dryad.tres"),
	]

