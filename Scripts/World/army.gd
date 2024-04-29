class_name Army
extends Node

var hero : Hero

var units_data : Array[DataUnit]

var units : Array[UnitForm]

var controller : Player

var coord : Vector2i

var alive : bool = true


func destroy_army():
	if hero != null:
		WM.kill_hero(hero)
	else:
		WM.grid[coord.x][coord.y].army = null

	queue_free()


func get_units_list():
	return units_data.duplicate()
