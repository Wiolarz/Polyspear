extends Node


@export var heavy_durability = 1
@export var light_durability = 2
var light_points = 0
var heavy_points = 0

func is_dead():  # returns true if character died
	return heavy_durability <= heavy_points

func light_damage(value=1):
	light_points += value
	while light_points >= light_durability:
		heavy_damage(1)
		light_points -= light_durability


func heavy_damage(value=1):
	heavy_points += value
#	if heavy_points >= heavy_durability:
#		print("character is dead")

func heal(value=1):
	light_points -= value
	if light_points < 0:
		light_points = 0

