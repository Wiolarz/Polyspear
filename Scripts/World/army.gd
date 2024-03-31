class_name Army
extends Node

var hero : Hero

var unit_scenes : Array[PackedScene]

var units : Array[AUnit]

var controller : Player

var cord : Vector2i

var alive : bool = true



func destroy_army():
	if hero != null:
		WM.kill_hero(hero)
	else:
		WM.grid[cord.x][cord.y].army = null
	
	queue_free()