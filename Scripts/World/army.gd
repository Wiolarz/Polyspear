class_name Army

extends Node

@export var hero : Hero

@export var unit_set : UnitSet

var controller : Player

var cord : Vector2i

var alive : bool = true



func destroy_army():
	if hero != null:
		WM.kill_hero(hero)
	else:
		WM.grid[cord.x][cord.y].army = null
	
	queue_free()