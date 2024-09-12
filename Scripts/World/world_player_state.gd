class_name WorldPlayerState
extends RefCounted

var goods : Goods = Goods.new()

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

var faction : DataFaction
