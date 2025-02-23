class_name City
extends Place


var buildings : Array[DataBuilding] = []

# ## when this is null, it should be replaced with controller's faction before
# ## anything is done



func interact(army : Army) -> void:
	if controller_index != army.controller_index:
		print("End of the game")
		pass#world_state.win_game(army.controller_index)  # TEMP TODO FIX


func on_end_of_round() -> void:
	faction.add_goods(Goods.new(0, 1, 0))
	for building in buildings:
		if building.name == "sawmill":
			faction.add_goods(Goods.new(3, 0, 0))


#region Heroes

func get_heroes_to_buy() -> Array[DataHero]:
	var result : Array[DataHero] = []
	for hero_data : DataHero in faction.race.heroes:
		result.append(hero_data)
	return result


func get_cost_description(hero: DataHero) -> String:
	if faction.has_hero(hero):
		return "✔"
	var cost = faction.get_hero_cost(hero)
	var resurrect : bool = faction.has_dead_hero(hero)
	if resurrect:
		return "Resurrect\n%s" % cost
	return "%s" % cost


func can_buy_hero(hero : DataHero) -> bool:
	if faction.has_hero(hero):
		return false
	#TEMP remove check for if defender_Army, as some army should always exist in city, even empty
	if defender_army and defender_army.hero:  # hero is present in city hex
		return false
	var cost : Goods = faction.get_hero_cost(hero)
	return faction.has_enough(cost)

#endregion


#region Units

func get_units_to_buy() -> Array[DataUnit]:
	var units : Array[DataUnit] = []
	for unit_data : DataUnit in faction.race.units_data:
		units.append(unit_data)
	return units


# func can_buy_unit(unit : DataUnit) -> bool:
# 	var army : Army = world_state.get_army_at(coord)
# 	if not army:
# 		return false
# 	if army.controller_index != controller_index:
# 		return false
# 	if army.units_data.size() >= army.hero.max_army_size:
# 		return false
# 	if not unit_has_required_building(world_state, unit):
# 		return false
# 	return world_state.has_player_enough(army.controller_index, unit.cost)


func unit_has_required_building(unit : DataUnit) -> bool:
	if not unit.required_building:
		return true
	return has_built(unit.required_building)

#endregion


#region Buildings

# TODO consider moving it to world_state
func build_building(building : DataBuilding) -> bool:
	if not can_build(building):
		return false
	if faction.player_purchase(building.cost):
		if not building.is_outpost_building():
			buildings.append(building)
		else:
			faction.outpost_buildings.append(building)
		return true
	return false


func has_built(building : DataBuilding) -> bool:
	var built_here : bool = building in buildings
	if built_here:
		return true
	return building in faction.outpost_buildings


func can_build(building : DataBuilding) -> bool:
	if has_built(building):
		return false
	if not faction.has_enough(building.cost):
		return false

	if building.is_outpost_building() and \
			not faction.has_this_outpost_type(building.outpost_requirement):
		return false

	return building.requirements \
		.all(func building_present(building_ : DataBuilding):
			return has_built(building_))


func to_specific_serializable(dict : Dictionary) -> void:
	dict["buildings"] = []
	for building in buildings:
		dict["buildings"].append(DataBuilding.get_network_id(building))


func paste_specific_serializable_state(dict : Dictionary) -> void:
	buildings = []
	for b in dict["buildings"]:
		buildings.append(DataBuilding.from_network_id(b))

	# var player = world_state.get_player_by_index(controller_index)
	# if player:
	# 	player.cities.append(self)

	# if "player" in dict and dict["player"] in range(players.size()):
	# 	players[dict["player"]].cities.append(self)


static func create_place(coord_ : Vector2i, args : PackedStringArray) -> Place:
	var player_index : int = -1
	for i in range(args.size()):
		if args[i].is_valid_int():
			if player_index >= 0:
				push_error("tried to set player index more than one time")
				return
			var value : int = args[i].to_int()
			if value >= 0:
				player_index = value
		else:
			push_error("unrecognised parameter: %s" % args[i])
	
	var result = City.new()
	result.controller_index = player_index
	# TODO move this somewhere else -- this should not be here
	result.coord = coord_
	result.movable = true

	# TODO check this fragment
	# var player : Faction = world_state.get_player_by_index(player_index)
	# if player:
	# 	result.controller_index = player_index
	# 	player.cities.append(result)

	return result
