class_name City
extends Place


var buildings : Array[DataBuilding] = []

# ## when this is null, it should be replaced with controller's faction before
# ## anything is done
# var faction : DataFaction


func get_faction(world_state : WorldState) -> DataFaction:
	var player = world_state.get_player(controller_index)
	if not player:
		return null
	return player.faction


func interact(world_state : WorldState, army : Army) -> bool:
	if controller_index != army.controller_index:
		world_state.win_game(army.controller_index)
		# FIXME
		return true
	return false


func on_end_of_turn(world_state : WorldState) -> void:
	var goods = world_state.get_player_by_index(controller_index).goods
	goods.add(Goods.new(0, 1, 0))
	for bulding in buildings:
		if bulding.name == "sawmill":
			goods.add(Goods.new(3, 0, 0))


#region Heroes

func get_heroes_to_buy(world_state : WorldState) -> Array[DataHero]:
	var result : Array[DataHero] = []
	for hero_data : DataHero in world_state.get_player(controller_index).faction.heroes:
		result.append(hero_data)
	return result


func get_cost_description(world_state : WorldState, hero: DataHero) -> String:
	var player = world_state.get_player(controller_index)
	if world_state.has_player_a_hero(controller_index, hero):
		return "✔"
	var cost = world_state.get_hero_cost_for_player(controller_index, hero)
	var resurrect : bool = world_state.has_player_a_dead_hero(controller_index, hero)
	if resurrect:
		return "Resurrect\n%s" % cost
	return "%s" % cost


func can_buy_hero(hero: DataHero, world_state : WorldState) -> bool:
	if world_state.has_player_a_hero(controller_index, hero):
		return false
	if world_state.get_army_at(coord):
		return false
	var cost = world_state.get_hero_cost_for_player(controller_index, hero)
	return world_state.has_player_enough(controller_index, cost)

#endregion


#region Units

func get_units_to_buy(world_state) -> Array[DataUnit]:
	var units : Array[DataUnit] = []
	for unit_data : DataUnit in get_faction(world_state).units_data:
		units.append(unit_data)
	return units


# func can_buy_unit(unit : DataUnit, world_state : WorldState) -> bool:
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


func unit_has_required_building(world_state : WorldState, unit : DataUnit) -> bool:
	if not unit.required_building:
		return true
	return has_built(world_state, unit.required_building)

#endregion


#region Buildings

# TODO consider moving it to world_state
func build_building(world_state : WorldState, building : DataBuilding) -> bool:
	if not can_build(world_state, building):
		return false
	var player = world_state.get_player(controller_index)
	if world_state.player_purchase(controller_index, building.cost):
		if not building.is_outpost_building():
			buildings.append(building)
		else:
			player.outpost_buildings.append(building)
		return true
	return false


func has_built(world_state : WorldState, building : DataBuilding) -> bool:
	var player = world_state.get_player(controller_index)
	var built_here : bool = building in buildings
	if built_here:
		return true
	return player and building in player.outpost_buildings


func can_build(world_state : WorldState, building : DataBuilding)-> bool:
	if has_built(world_state, building):
		return false
	if not world_state.has_player_enough(controller_index, building.cost):
		return false

	if building.is_outpost_building() and \
			not world_state.has_player_any_outpost( \
				controller_index, building.outpost_requirement):
		return false

	return building.requirements \
		.all(func b_present(b:DataBuilding): return has_built(world_state, b))


func to_specific_serializable(dict : Dictionary) -> void:
	dict["buildings"] = []
	for building in buildings:
		dict["buildings"].append(DataBuilding.get_network_id(building))


func paste_specific_serializable_state(dict : Dictionary) -> void:
	buildings = []
	for b in dict["buildings"]:
		buildings.append(DataBuilding.from_network_id(b))

	# var player = world_state.get_player(controller_index)
	# if player:
	# 	player.cities.append(self)

	# if "player" in dict and dict["player"] in range(players.size()):
	# 	players[dict["player"]].cities.append(self)


static func create_place(args : PackedStringArray, coord_ : Vector2i) -> Place:
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
	# var player : WorldPlayerState = world_state.get_player(player_index)
	# if player:
	# 	result.controller_index = player_index
	# 	player.cities.append(result)

	return result
