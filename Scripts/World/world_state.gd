class_name WorldState
extends RefCounted

const MOVE_IS_INVALID = -1

var grid : GenericHexGrid = null
var turn_counter : int = 0
var current_player_index : int = 0
var player_states : Array[WorldPlayerState] = []
var move_hold_on_combat : Array[Vector2i] # TODO some better form

## consider not to use signals
signal player_created(player : Player)
signal army_created(army : Army)
signal army_updated(army : Army)
signal army_moved(army : Army)
signal army_destroyed(army : Army)
signal place_changed(coord : Vector2i)
signal turn_changed()

## this is signal used by other managers
signal combat_started(armies : Array, coord : Vector2i)


#region init

func _init(width_ : int, height_ : int):
	grid = GenericHexGrid.new(width_, height_, WorldHex.new())


static func create(map: DataWorldMap,
		slots : Array[GameSetupInfo.Slot],
		ser : SerializableWorldState) -> WorldState:
	var result = WorldState.new(map.grid_width, map.grid_height)


	# load players and their not related-to-grid state
	result.player_states.resize(slots.size())
	for i in result.player_states.size():
		result.player_states[i] = WorldPlayerState.new()
		var player = result.player_states[i]
		var slot = slots[i]
		player.faction = slot.faction
		if not ser:
			player.goods = CFG.get_start_goods()
		else:
			player.goods = Goods.from_array(ser.players[i].goods)
			for dead_hero_ser in ser.players[i].dead_heroes:
				player.dead_heroes.append(Hero.from_network_serializable(
					dead_hero_ser, i))
			for outpost_building_ser in ser.players[i].outpost_buildings:
				player.outpost_buildings.append(DataBuilding.from_network_id(
					outpost_building_ser))


	# init places and armies from map or map and saved game
	for x in map.grid_width:
		for y in map.grid_height:
			var coord := Vector2i(x, y)
			var hex : WorldHex = WorldHex.new()
			hex.data_tile = map.grid_data[x][y]
			var place_ser : Dictionary = {}
			var type : String = hex.data_tile.type
			if ser:
				place_ser = ser.place_hexes.get(coord, {})
				if place_ser.size() > 0:
					type = place_ser["type"]
			hex.init_place(type, coord, place_ser)
			# TODO somehow get this inside of
			# creation
			result.grid.set_hex(coord, hex)
			if not ser and hex.place:
				var army_preset = hex.place.get_army_at_start()
				if army_preset:
					result.spawn_army_from_preset(army_preset, coord, \
						hex.place.controller_index)
			if ser and coord in ser.army_hexes:
				var loaded : Dictionary = ser.army_hexes[coord]
				var army : Army = null
				if loaded:
					army = _deserialize_army_wip(loaded)
				if army:
					hex.army = army
					army.coord = coord

	result.synchronize_players_with_their_places()

	if not ser:
		result.current_player_index = 0
	else:
		result.current_player_index = ser["current_player"]

	return result


## fills up players' fields like `cities` and `outposts` after place grid is
## filled with new map or loaded state
func synchronize_players_with_their_places() -> void:
	for player in player_states:
		player.cities = []
		player.outposts = []
	for x in grid.width:
		for y in grid.height:
			var coord := Vector2i(x, y)
			var city = get_city_at(coord)
			var outpost = get_place_at(coord) as Outpost
			if city:
				var player = get_player(city.controller_index)
				if player:
					player.cities.append(city)
			if outpost:
				var player = get_player(outpost.controller_index)
				if player:
					player.outposts.append(outpost)



#endregion


func get_current_player() -> WorldPlayerState:
	if current_player_index in range(player_states.size()):
		return player_states[current_player_index]
	return null


func get_player_index(player : WorldPlayerState) -> int:
	for i in range(player_states.size()):
		if player == player_states[i]:
			return i
	return -1


func get_player(index : int) -> WorldPlayerState:
	return get_player_by_index(index)


func get_player_by_index(index : int) -> WorldPlayerState:
	if index < 0:
		return null
	if index >= player_states.size():
		return null
	return player_states[index]


func check_move_allowed(world_move_info : WorldMoveInfo) -> String:
	if world_move_info.move_type == WorldMoveInfo.TYPE_TRAVEL:
		var source : Vector2i = world_move_info.move_source
		var target : Vector2i = world_move_info.target_tile_coord
		return check_army_travel(source, target)
	if world_move_info.move_type == WorldMoveInfo.TYPE_RECRUIT_HERO:
		var player_index : int = world_move_info.recruit_hero_info.player_index
		var hero_data : DataHero = world_move_info.recruit_hero_info.data_hero
		var coord : Vector2i = world_move_info.target_tile_coord
		return check_recruit_hero(player_index, hero_data, coord)
	elif world_move_info.move_type == WorldMoveInfo.TYPE_RECRUIT_UNIT:
		var army_coord : Vector2i = world_move_info.target_tile_coord
		var city_coord : Vector2i = world_move_info.move_source
		var unit : DataUnit = world_move_info.data
		return check_recruit_unit(unit, city_coord, army_coord)
	elif world_move_info.move_type == WorldMoveInfo.TYPE_START_TRADE:
		var source : Vector2i = world_move_info.move_source
		var target : Vector2i = world_move_info.target_coord
		return check_start_trade(source, target)
	if world_move_info.move_type == WorldMoveInfo.TYPE_BUILD:
		var city_coord : Vector2i = world_move_info.target_tile_coord
		var building : DataBuilding = world_move_info.data
		return check_build_building(city_coord, building)
	elif world_move_info.move_type == WorldMoveInfo.TYPE_END_TURN:
		return check_end_turn()
	return "unrecognised move"


func do_move(world_move_info : WorldMoveInfo) -> bool:
	var problem := check_move_allowed(world_move_info)
	if problem != "":
		push_error(problem)
		return false
	if world_move_info.move_type == WorldMoveInfo.TYPE_TRAVEL:
		var source : Vector2i = world_move_info.move_source
		var target : Vector2i = world_move_info.target_tile_coord
		return do_army_travel(source, target)
	elif world_move_info.move_type == WorldMoveInfo.TYPE_RECRUIT_HERO:
		var player_index : int = world_move_info.recruit_hero_info.player_index
		var data_hero : DataHero = world_move_info.recruit_hero_info.data_hero
		var coord : Vector2i = world_move_info.target_tile_coord
		return do_recruit_hero(player_index, data_hero, coord)
	elif world_move_info.move_type == WorldMoveInfo.TYPE_RECRUIT_UNIT:
		var army_coord : Vector2i = world_move_info.target_tile_coord
		var city_coord : Vector2i = world_move_info.move_source
		var unit : DataUnit = world_move_info.data
		return do_recruit_unit(unit, city_coord, army_coord)
	elif world_move_info.move_type == WorldMoveInfo.TYPE_START_TRADE:
		var source : Vector2i = world_move_info.move_source
		var target : Vector2i = world_move_info.target_coord
		return do_start_trade(source, target)
	if world_move_info.move_type == WorldMoveInfo.TYPE_BUILD:
		var city_coord : Vector2i = world_move_info.target_tile_coord
		var building : DataBuilding = world_move_info.data
		return do_build_building(city_coord, building)
	elif world_move_info.move_type == WorldMoveInfo.TYPE_END_TURN:
		return do_end_turn()
	return true


func check_start_trade(source : Vector2i, target : Vector2i) -> String:
	var army : Army = get_army_at(source)
	if not army:
		return "please choose army to start trade"
	var city : City = get_city_at(target)
	if not city:
		return "please choose city to start trade"
	if army.controller_index != current_player_index:
		return "this army has not turn now"
	if city.controller_index != current_player_index:
		return "this city has not turn now"
	return ""


func check_build_building(city_coord : Vector2i, building : DataBuilding) \
		-> String:
	var city : City = get_city_at(city_coord)
	if not city:
		return "cannot build buildings without city"
	if city.controller_index != current_player_index:
		return "cannot build in other's player city"
	if not city.can_build(self, building):
		# TODO move this check here probably and divide this error message
		return "this city is not able to build this"
	return ""


func check_recruit_unit(data_unit : DataUnit, city_coord : Vector2i,
		army_coord : Vector2i) -> String:
	var army : Army = get_army_at(army_coord)
	if not army:
		return "no army at coord"
	if army.controller_index != current_player_index:
		return "target army has not turn now"
	if army.hero and army.units_data.size() >= army.hero.max_army_size:
		return "this hero has maximum size of army now"
	var city = get_city_at(city_coord)
	if not city:
		return "no city chosen"
	if army_coord != city_coord and \
			not GenericHexGrid.is_adjacent(army_coord, city_coord):
		return "army has to be in city or next to it"
	if city.controller_index != army.controller_index:
		return "cannot recruit not in own city"
	# TODO optimize this...
	if not data_unit in city.get_units_to_buy(self):
		return "cannot recruit such unit in this city"
	if not city.unit_has_required_building(self, data_unit):
		return "not all required buildings are build in this city"
	if not has_player_enough(army.controller_index, data_unit.cost):
		return "not enough resources for this unit, need %s" % data_unit.cost
	return ""


func check_recruit_hero(player_index : int, data_hero : DataHero,
		coord : Vector2i) -> String:
	if get_army_at(coord):
		return "cannot recruit hero where some army already is"
	var city : City = get_city_at(coord)
	if not city:
		return "must recruit hero in a city"
	if player_index != current_player_index:
		return "this player has not turn now"
	if player_index != city.controller_index:
		return "player does not own the city where tries to recruit"
	if has_player_a_hero(player_index, data_hero):
		return "hero is already recruited"
	var player = get_player(player_index)
	if not data_hero in player.faction.heroes:
		return "player's faction does not fit for this hero"
	var cost = get_hero_cost_for_player(player_index, data_hero)
	if not has_player_enough(player_index, cost):
		return "not enough cash, needed %s" % cost
	return ""


func check_end_turn() -> String:
	if player_states.size() < 1:
		return "no players"
	return ""


## this function spawns an army from preset on given coord
func spawn_army_from_preset(army_preset : PresetArmy, coord : Vector2i, \
		player_index : int) -> void:
	if get_army_at(coord):
		push_error("tried to spawn army at occupied tile")
		# TODO make option for neutral army to spawn and attack player
	print("spawn army at %s" % coord)
	var army = Army.create_from_preset(army_preset)
	army.coord = coord
	army.controller_index = player_index
	# TODO add this army to player armies array
	grid.get_hex(coord).army = army
	army_created.emit(army)


func get_hero_cost_for_player(player_index : int, hero_data : DataHero) \
		-> Goods:
	var player = get_player(player_index)
	if not player:
		return Goods.new(0, 0, 0)
	if has_player_a_dead_hero(player_index, hero_data):
		return hero_data.revive_cost
	return hero_data.cost


## returns true only of move was legal and recruitment took place
func do_recruit_unit(data_unit : DataUnit, city_coord : Vector2i,
		army_coord : Vector2i) -> bool:
	var problem := check_recruit_unit(data_unit, city_coord, army_coord)
	if problem != "":
		push_error(problem)
		return false
	var army : Army = get_army_at(army_coord)
	var player = get_player(army.controller_index)
	var purchased : bool = player_spend(army.controller_index, data_unit.cost)
	assert(purchased)
	army.units_data.append(data_unit)
	return true


## returns army reference if success/legal, null otherwise
func do_recruit_hero(player_index : int, data_hero : DataHero,
		coord : Vector2i) -> bool:
	var problem := check_recruit_hero(player_index, data_hero, coord)
	if problem != "":
		push_error(problem)
		return false
	var city : City = get_city_at(coord)
	var player = get_player(player_index)

	var cost = get_hero_cost_for_player(player_index, data_hero)
	var purchased = player_purchase(player_index, cost)
	assert(purchased)

	var army : Army = Army.new() # TODO maybe make some function

	# TODO check this hero can be recruited here by game rules

	var hero : Hero # = Hero.create_hero(hero_data, city.controller)
	# now we need to check if this hero was already recruited, but died
	for dead_hero in player.dead_heroes:
		if dead_hero.template == data_hero:
			dead_hero.revive()
			dead_hero.controller_index = player_index
			hero = dead_hero
	if not hero: # means no hero is revived
		hero = Hero.construct_hero(data_hero, player_index)

	army.hero = hero
	army.controller_index = city.controller_index
	army.coord = coord
	army.units_data.append(data_hero.data_unit)

	grid.get_hex(coord).army = army
	player.hero_armies.append(army)

	army_created.emit(army)

	return true


func do_start_trade(source : Vector2i, target : Vector2i) -> bool:
	var problem := check_start_trade(source, target)
	if problem != "":
		push_error(problem)
		return false
	return true



func get_hero_to_buy_in_city(city : City, hero_index : int) -> DataHero:
	if not city:
		return null
	var array = city.get_faction(self).heroes
	if hero_index in range(array.size()):
		return array[hero_index]
	return null


func do_build_building(coord : Vector2i, building : DataBuilding) -> bool:
	var problem := check_build_building(coord, building)
	if problem != "":
		push_error(problem)
		return false
	var city := get_city_at(coord)
	return city.build_building(self, building)


func has_player_a_hero(player_index : int, hero : DataHero) -> bool:
	var player = get_player(player_index)
	if not player:
		return false
	for hero_army in player.hero_armies:
		if hero_army.hero.template == hero:
			return true
	return false


func find_dead_hero_of_player(player_index : int, data_hero : DataHero) -> Hero:
	var player = get_player(player_index)
	if not player:
		return null
	for hero in player.dead_heroes:
		if hero.template == data_hero:
			return hero
	return null


func has_player_a_dead_hero(player_index : int, data_hero : DataHero) -> bool:
	return find_dead_hero_of_player(player_index, data_hero) != null


func has_player_enough(player_index : int, goods : Goods) -> bool:
	var player = get_player(player_index)
	return player and player.goods.has_enough(goods)


func has_player_any_outpost(player_index : int, outpost_type : String) -> bool:
	var player = get_player(player_index)
	if not player:
		return false
	for outpost in player.outposts:
		if outpost.outpost_type == outpost_type:
			return true
	return false


func player_purchase(player_index : int, cost : Goods) -> bool:
	return player_spend(player_index, cost)


func player_spend(player_index : int, cost : Goods) -> bool:
	var player = get_player(player_index)
	if not player:
		push_error("no player with this index, so cannot buy")
		return false
	if player.goods.has_enough(cost):
		player.goods.subtract(cost)
		return true
	print("not enough money")
	return false


func check_army_travel(source : Vector2i, target : Vector2i) -> String:
	var army : Army = get_army_at(source)
	var current_player = get_player(current_player_index)
	if not army:
		return "no army at source hex"
	if source == target:
		return "cannot travel to the same hex"
	if army.controller_index != current_player_index:
		return "now is not this army's turn"
	if not GenericHexGrid.is_adjacent(source, target):
		return "cannot move more than one hex at a time"
	if not is_hex_movable(target):
		return "target hex is not movable"
	if army.get_movement_points() <= 0:
		return "not enough movement points"
	if not is_enemy_at(target, army.controller_index) and get_army_at(target):
		return "cannot move into non-enemy army"
	var city = get_city_at(target)
	if city and city.controller_index != current_player_index:
		return "sieges are not present yet"
	return ""


## this is the basicest move
func do_army_travel(source : Vector2i, target : Vector2i) -> bool:
	var problem = check_army_travel(source, target)
	if problem != "":
		push_error(problem)
		return false
	var army : Army = get_army_at(source)
	var current_player = get_player(current_player_index)

	var player = get_player(army.controller_index)

	if is_enemy_at(target, army.controller_index):
		var fighting_armies : Array[Army] = [army, get_army_at(target)]
		var has_combat_started : bool = start_combat_by_attack(fighting_armies, \
			source, target)
		return has_combat_started

	var spent = army_spend_movement_points(army, 1)
	assert(spent)

	print("moving ", army," to ",target)
	change_army_position(army, target)
	interact_place(army, target)
	return true


func start_combat_by_attack(armies : Array[Army], source : Vector2i, \
		target : Vector2i) -> bool:
	move_hold_on_combat = [source, target]
	combat_started.emit(armies, target)
	return true


func end_combat(army_updates : Array[Dictionary]) -> bool:
	if move_hold_on_combat.size() < 1:
		return false
	for update in army_updates:
		var army = update["army"]
		var killed = update["killed"]
		var xp = update["xp"]
		var losses = update["losses"]
		if killed:
			remove_army(army)
		else:
			if losses is Array and losses.size() > 0:
				army.apply_losses(losses)
			if xp > 0:
				army.add_xp(xp)

	var source : Vector2i = move_hold_on_combat[0]
	var target : Vector2i = move_hold_on_combat[1]
	if check_army_travel(source, target) == "":
		do_army_travel(source, target)

	return true


## returns if place is interacted
## TODO consider what we should return here
func interact_place(army : Army, coord : Vector2i) -> bool:
	var place = get_place_at(coord)
	if not place:
		return false
	place.interact(self, army)
	print("unsupported place type to interact")
	return false


## returns if place is captured
## TODO consider what we should return here
func capture_place(player_index : int, coord : Vector2i) -> bool:
	var place = get_place_at(coord)
	if not place:
		return false
	place.capture(self, player_index)
	print("unsupported place type to capture")
	return false


func _delete_outpost_buildings_if_needed(player_index : int) -> void:
	var player = get_player(player_index)
	if not player:
		return
	var new_array : Array[DataBuilding] = []
	for upgrade in player.outpost_buildings:
		for outpost in player.outposts:
			if outpost.outpost_type == upgrade.outpost_requirement:
				new_array.append(upgrade)
				break
	player.outpost_buildings = new_array


func get_interactable_type_at(coord : Vector2i) -> String:

	if get_army_at(coord):
		return "army"

	if get_city_at(coord):
		return "city"

	return "empty"


func get_army_at(coord : Vector2i) -> Army:
	var hex : WorldHex = grid.get_hex(coord)
	if hex:
		return hex.army
	return null


func place_army_at(coord : Vector2i, army : Army) -> void:
	var hex : WorldHex = grid.get_hex(coord)
	assert(not hex.army, "cannot place army on occupied hex %s" % coord)
	hex.army = army
	army.coord = coord


func remove_army(army : Army) -> void:
	assert(army == get_army_at(army.coord))
	var hex : WorldHex = grid.get_hex(army.coord)
	hex.army = null
	var player_index = army.controller_index
	var player = get_player(player_index)
	if player:
		var army_array = player.hero_armies
		assert(army in army_array)
		army_array.erase(army)
		player.dead_heroes.append(army.hero)
	# think about when is this ref counted object destroyed
	army_destroyed.emit(army)


func get_place_at(coord : Vector2i) -> Place:
	var hex : WorldHex = grid.get_hex(coord)
	if hex:
		return hex.place
	return null


func get_city_at(coord : Vector2i) -> City:
	return get_place_at(coord) as City


func is_enemy_at(coord : Vector2i, player_index : int) -> bool:
	var army : Army = get_army_at(coord)
	return army and army.controller_index != player_index


func is_hex_movable(coord : Vector2i) -> bool:
	var hex : WorldHex = grid.get_hex(coord)
	return hex and hex.place and hex.place.movable


func get_battle_map_at(_coord : Vector2i, army_size : int) -> DataBattleMap:
	if army_size > 5:
		return CFG.BIGGER_BATTLE_MAP

	return CFG.DEFAULT_BATTLE_MAP


func get_all_places() -> Array[Place]:
	var result : Array[Place] = []
	for x in range(grid.grid_width):
		for y in range(grid.grid_height):
			var coord := Vector2i(x, y)
			var place : Place = grid.get_hex(coord).place
			if place:
				result.append(place)
	return result


func get_top_left_hex() -> WorldHex:
	return grid.get_hex(Vector2i(0, 0))


func get_bottom_right_hex() -> WorldHex:
	var coord := Vector2i(grid.width - 1, grid.height - 1)
	return grid.get_hex(coord)


## returns true when points can be spent, false when not
func army_can_spend_movement_points(army : Army, points : int) -> bool:
	if army.get_movement_points() < points:
		return false
	return true


## returns true when points points are spent, false when could not
func army_spend_movement_points(army : Army, points : int) -> bool:
	if not army_can_spend_movement_points(army, points):
		return false
	army.hero.movement_points -= points
	return true



func change_army_position(army : Army, target_coord : Vector2i) -> void:
	assert(get_army_at(army.coord) == army, "army coord desync")
	var source_hex = grid.get_hex(army.coord)
	var target_hex = grid.get_hex(target_coord)
	assert(target_hex, \
		"can't place armies on non existing tile %s" % target_coord)
	assert(not target_hex.army, \
		"can't place armies on occupied tile %s" % target_coord)
	source_hex.army = null
	target_hex.army = army
	army.coord = target_coord
	army_updated.emit(army)


func get_interactable_at(coord : Vector2i) -> Object:
	var army = get_army_at(coord)
	if army:
		return army
	var city = get_city_at(coord)
	if city:
		return city
	return null


func do_end_turn() -> bool:
	var problem := check_end_turn()
	if problem != "":
		push_error(problem)
		return false
	_end_of_turn_callbacks(current_player_index)
	if current_player_index == player_states.size():
		_end_of_round_callbacks()
	current_player_index = (current_player_index + 1) % player_states.size()
	turn_changed.emit()
	return true


func to_network_serializable() -> SerializableWorldState:
	var result := SerializableWorldState.new()
	for col_index in grid.hexes.size():
		var col = grid.hexes[col_index]
		for hex_index in col.size():
			var coord = Vector2i(col_index, hex_index)
			var hex = col[hex_index]
			assert(hex)
			var place = hex.place
			# TODO later handle modified places (changed to basic)
			# (if ever needed)
			if place and not place.is_basic():
				result.place_hexes[coord] = \
					Place.get_network_serializable(place)
			var army = hex.army
			if army:
				result.army_hexes[coord] = _get_serialized_army(army)
	result.players.resize(player_states.size())
	for player_index in player_states.size():
		var player = player_states[player_index]
		result.players[player_index] = SerializableWorldState.PlayerState.new()
		var ser = result.players[player_index]
		ser.goods = player.goods.to_array()
		ser.dead_heroes.resize(player.dead_heroes.size())
		for dead_hero_index in player.dead_heroes.size():
			ser.dead_heroes[dead_hero_index] = \
				player.dead_heroes[dead_hero_index] \
					.to_network_serializable()
		ser.outpost_buildings.resize(player.outpost_buildings.size())
		for outpost_building_index in player.outpost_buildings.size():
			ser.outpost_buildings[outpost_building_index] = \
				DataBuilding.get_network_id(
					player.outpost_buildings[outpost_building_index])
	result.current_player = current_player_index
	return result


func _get_serialized_army(army) -> Dictionary:
	var army_dict : Dictionary = {}
	army_dict["player"] = army.controller_index

	if army.hero:
		var hero : Hero = army.hero
		army_dict["hero"] = hero.to_network_serializable()

	army_dict["units"] = []
	var unit_array = army_dict["units"]
	for unit in army.units_data:
		unit_array.append(DataUnit.get_network_id(unit))

	return army_dict


static func _deserialize_army_wip(dict : Dictionary) -> Army:
	var army : Army = Army.new()
	army.controller_index = dict["player"]
	if "hero" in dict:
		army.hero = Hero.from_network_serializable(dict["hero"], dict["player"])
	for unit_ser in dict["units"]:
		army.units_data.append(DataUnit.from_network_id(unit_ser))
	return army



func _end_of_turn_callbacks(player_index : int) -> void:
	#TODO make it nicer
	for x in range(grid.width):
		for y in range(grid.height):
			var coord = Vector2i(x,y)
			var army : Army = grid.get_hex(coord).army
			if army:
				army.on_end_of_turn(player_index)
			var place : Place = get_place_at(coord)
			if place:
				place.on_end_of_turn(self)


func _end_of_round_callbacks() -> void:
	for place in get_all_places():
		place.on_end_of_round()
