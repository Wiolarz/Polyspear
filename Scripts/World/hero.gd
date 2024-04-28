class_name Hero
extends Node

#debug
var template : DataHero

# code
var army : Army
var controller : Player
var coord : Vector2i
# visual
var target_tile : HexTile


# gameplay
var hero_name : String

var data_unit : DataUnit 

var max_army_size : int

var max_movement_points = 3
var movement_points = 3


static func create_hero(data_hero : DataHero) -> Hero:
	var new_hero = Hero.new()
	new_hero.template = data_hero

	new_hero.hero_name = data_hero.hero_name
	new_hero.data_unit = data_hero.data_unit
	new_hero.max_army_size = data_hero.max_army_size
	new_hero.max_movement_points = data_hero.max_movement_points
	return new_hero


func trade(_another_hero : Hero):
	print("trade menu")


func move(target : HexTile):
	target_tile = target

