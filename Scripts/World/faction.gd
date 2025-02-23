class_name Faction
extends RefCounted



var controller_index : int
var controller : Player:
	get:
		return IM.get_player_by_index(controller_index)


var _goods : Goods = Goods.new()

var capital_city : City:
	get:
		if cities.size() == 0:
			return null
		return cities[0]
	set(_wrong_value):
		assert(false, "attempt to modify read only value of player capital_city")

var cities : Array[City]
var outposts : Array[Outpost]
var outpost_buildings : Array[DataBuilding]

var hero_armies : Array[Army] = []

var dead_heroes: Array[Hero] = []

var race : DataRace


static func create_world_player_state(slot : Slot) -> Faction:
	var new_faction := Faction.new()

	new_faction.controller_index = slot.index
	new_faction.race = slot.race

	return new_faction



#region Goods + City Economy

## Used during starting new game and loading a save
func set_goods(new_goods_value : Goods) -> void:
	_goods = new_goods_value


func add_goods(new_goods : Goods) -> void:
	_goods.add(new_goods)

## Checks if player has enough goods for purchase
func has_enough(cost : Goods) -> bool:
	return _goods.has_enough(cost)


## If there are sufficient goods returns true + goods are subtracted
func try_to_pay(cost : Goods) -> bool:
	if _goods.has_enough(cost):
		_goods.subtract(cost)
		return true
	print("not enough money")
	return false


func has_this_outpost_type(outpost_type : String) -> bool:
	for outpost in outposts:
		if outpost.outpost_type == outpost_type:
			return true
	return false


## Removes outpost from occupied outpost list,
## it may additionaly remove buildings which required outpost type to be present
func raised_outpost(outpost : Outpost) -> void:
	outposts.erase(outpost)
	if not has_this_outpost_type(outpost.outpost_type):
		for building in outpost_buildings:
			if building.outpost_requirement == outpost.outpost_type:
				outpost_buildings.erase(building)

#endregion Goods + City Economy

#region Heroes

func has_hero(data_hero : DataHero) -> bool:
	for hero_army in hero_armies:
		if hero_army.hero.template == data_hero:
			return true
	return false


func has_dead_hero(data_hero : DataHero) -> bool:
	for hero in dead_heroes:
		if hero.template == data_hero:
			return true
	return false

func get_hero_cost(data_hero : DataHero) -> Goods:
	if has_dead_hero(data_hero):
		return data_hero.revive_cost
	return data_hero.cost

#endregion Heroes

