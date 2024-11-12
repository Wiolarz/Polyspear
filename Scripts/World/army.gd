class_name Army
extends RefCounted # RefCounted is default

var units_data : Array[DataUnit]

var hero : Hero

var controller_index : int

var coord : Vector2i


#TEMP
var timer_reserve_sec : int
var timer_increment_sec : int


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
		hero.wounded = true
		print("hero wounded")
	for loss in losses:
		#assert(loss in units_data, "loss not in army")
		units_data.erase(loss)


func heal_in_city():
	if hero and hero.wounded:
		hero.wounded = false
		print("hero healed")


func get_movement_points() -> int:
	if hero:
		return hero.movement_points
	return 0


func add_xp(gained_xp : int) -> void:
	if hero:
		hero.add_xp(gained_xp)


func on_end_of_turn(player_index : int):
	if player_index == controller_index and hero:
		hero.movement_points = hero.max_movement_points


## remember that is some player's army is created, it also needs to be
static func create_from_preset(army_preset : PresetArmy) \
		-> Army:
	var new_army = Army.new()
	new_army.units_data = army_preset.units
	new_army.controller_index = -1
	#new_army.hero = Hero.construct_hero(army_preset.hero, -1) # TODO
	return new_army
