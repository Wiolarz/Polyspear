class_name Army
extends RefCounted # RefCounted is default

var units_data : Array[DataUnit]

var hero : Hero

var controller : Player

var coord : Vector2i


func destroy_army():
	if hero != null:
		WM.kill_hero(hero)
	else:
		WM.grid[coord.x][coord.y].army = null

	free()


func get_units_list():
	return units_data.duplicate()


func apply_losses(losses : Array[DataUnit]):
	if hero and hero.data_unit in losses:
		print("hero wounded")
	for loss in losses:
		assert(loss in units_data, "loss not in army")
		units_data.erase(loss)


func heal_in_city():
	if hero and hero.data_unit not in units_data:
		units_data.insert(0,hero.data_unit)
		print("hero healed")


static func create_army_from_preset(army_preset : PresetArmy) -> Army:
	var new_army = Army.new()
	new_army.units_data = army_preset.units
	#new_army.hero = army_preset.hero  # TODO ARMY PRESET HERO
	return new_army
