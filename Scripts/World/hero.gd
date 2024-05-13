class_name Hero
extends Node

#debug
var template : DataHero

# code
var controller : Player
var army : Army
var coord : Vector2i
# visual
var target_tile : TileForm


# gameplay
var hero_name : String

var data_unit : DataUnit

var max_army_size : int

var max_movement_points = 3
var movement_points = 3

var xp = 0
var level = 1

static func create_hero(data_hero : DataHero, player : Player) -> Hero:
	for dead_hero in player.dead_heroes:
		if dead_hero.template == data_hero:
			dead_hero.revive()
			dead_hero.controller = player
			return dead_hero

	var new_hero = Hero.new()
	new_hero.template = data_hero
	new_hero.hero_name = data_hero.hero_name
	new_hero.name = "Hero_" + data_hero.hero_name
	new_hero.controller = player
	new_hero.data_unit = data_hero.data_unit
	new_hero.max_army_size = data_hero.max_army_size
	new_hero.max_movement_points = data_hero.max_movement_points
	return new_hero


func _init():
	name = "Hero"


func trade(_another_hero : Hero):
	print("trade menu")


func move(target : TileForm):
	target_tile = target


func add_xp_for_casualties(killed : Array[DataUnit], enemy_hero : Hero) -> void:
	var levels = []
	for u in killed:
		levels.append(u.level)
	if enemy_hero:
		levels.append(enemy_hero.level)
	levels.sort()
	for l in levels:
		if l >= level:
			xp += 1
			print("%s gained xp, now has %d" % [hero_name, xp])
			if xp >= 2:
				level_up()


func level_up() -> void:
	if level == CFG.HERO_LEVEL_CAP:
		return
	xp = 0
	level += 1
	print("%s leveled up, now has level %d" % [hero_name, level])
	var old_max_move = max_movement_points
	max_army_size = 2 + level
	max_movement_points =  3 + (level / 2)
	movement_points += max_movement_points - old_max_move


func revive():
	movement_points = max_movement_points
