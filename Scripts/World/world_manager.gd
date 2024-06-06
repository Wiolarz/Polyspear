# Singleton - WM
extends Node

signal world_move_done

#region Setup Parameters

var players : Array[Player] = []

#endregion


#region Variables
var world_ui : WorldUI = null
var current_player : Player

## Only army that has a hero can move (army can only have a single hero)
var selected_hero : ArmyForm
var combat_tile : Vector2i

var _batch_mode : bool = false

#endregion


#region helpers


func world_game_is_active() -> bool:
	return players.size() > 0


func get_bounds_global_position() -> Rect2:
	return W_GRID.get_bounds_global_position()


func set_selected_hero(new_hero : ArmyForm):
	print("selected ", new_hero)
	if selected_hero:
		selected_hero.set_selected(false)
		world_ui.show_trade_ui(current_player.capital_city, null)
	selected_hero = new_hero
	if selected_hero:
		selected_hero.set_selected(true)
	world_ui.refresh_heroes(current_player)


func spawn_neutral_army(army_preset : PresetArmy, coord : Vector2i) -> ArmyForm:
	var player_army_presence = W_GRID.get_army(coord)
	if player_army_presence != null:
		printerr("neutral army attacking player has not been implemented") # TODO FIX

	print("neutral army spawn on: ", str(coord))
	var army_for_world_map : ArmyForm = \
		ArmyForm.create_neutral_army(army_preset)

	add_child(army_for_world_map, true)

	W_GRID.place_army(army_for_world_map, coord)
	return army_for_world_map

#endregion # helpers


#region Main functions


func get_player_index(player : Player) -> int:
	for i in range(players.size()):
		if player == players[i]:
			return i
	return -1


func get_player_by_index(index : int) -> Player:
	if index < 0:
		return null
	if index >= players.size():
		return null
	return players[index]


func next_player_turn():
	var world_move_info = WorldMoveInfo.make_end_turn()
	if not NET.client:
		perform_world_move_info(world_move_info)
	else:
		NET.client.queue_request_world_move(world_move_info)


func do_local_end_the_turn():
	set_selected_hero(null)
	world_ui.refresh_heroes(current_player)
	world_ui.show_trade_ui(current_player.capital_city, null)

	_end_of_turn_callbacks(current_player)
	var player_idx = players.find(current_player)
	if player_idx + 1 == players.size():
		_end_of_round_callbacks()
		current_player = players[0]
	else:
		current_player = players[player_idx + 1]
	world_ui.show_trade_ui(current_player.capital_city, null)


func _end_of_turn_callbacks(player : Player):
	W_GRID.end_of_turn_callbacks(player)


func _end_of_round_callbacks() -> void:
	W_GRID._end_of_round_callbacks()

#endregion


#region Player Actions

## Called when player interacts (presses) on the map tile
## Selects objects OR orders selected object
## City/Heroes -> orders Heroes
func grid_input(coord : Vector2i):
	print("world input @", coord)

	if BM.should_block_world_interaction():
		print("blocked by BM - Battle Manager")
		return

	if selected_hero == null:
		input_try_select(coord)
		return

	#TEMP in future there will be pathfiding here
	if not GenericHexGrid.is_adjacent(selected_hero.coord, coord):
		set_selected_hero(null)
		return

	try_interact(selected_hero, coord)

## Tries to Select owned Hero
func input_try_select(coord) -> void:  #TODO "nothing is selected try to select stuff"
	var selected_spot_type : String = W_GRID.get_interactable_type(coord)
	if selected_spot_type == "army":
		var army_form := W_GRID.get_army(coord)
		if current_player == army_form.entity.controller:
			set_selected_hero(army_form)

	if selected_spot_type == "city":
		var city := W_GRID.get_city(coord)
		if city.controller == current_player:
			world_ui.city_ui.show_recruit_heroes()



func try_interact(hero : ArmyForm, coord : Vector2i):

	var start_coords = hero.coord
	var world_move_info := \
		WorldMoveInfo.make_world_move(start_coords, coord)
	if not NET.client:
		perform_world_move_info(world_move_info)
	else:
		NET.client.queue_request_world_move(world_move_info)



func do_local_hero_move(hero : ArmyForm, coord : Vector2i):
	W_GRID.change_army_position(hero, coord)
	world_ui.show_trade_ui(current_player.capital_city, null)
	var place = W_GRID.get_place(coord)
	if place:
		place.interact(hero)


func trade_armies(_second_army : ArmyForm):
	#TODO
	print("trading armies")


func perform_world_move_info(world_move_info : WorldMoveInfo) -> void:
	print(NET.get_role_name(), " performing world move ", world_move_info)
	# TODO replay.record_move
	# TODO replay.save
	if NET.server:
		NET.server.broadcast_world_move(world_move_info)
	if world_move_info.move_type == WorldMoveInfo.TYPE_MOVE:
		var hero : ArmyForm = W_GRID.get_army(world_move_info.move_source)
		# TODO if there is no hero trigger desync
		if not hero:
			push_error("no hero")
			NET.desync() # TODO should be only on client xd
			# TODO desync or kick clinet who tried illegal move
			return

		var player = hero.controller
		var coord = world_move_info.target_tile_coord

		if W_GRID.is_enemy_present(coord, player):
			if not hero.has_movement_points():
				print("not enough movement points")
				return
			start_combat_by_attack(hero, coord)

		if W_GRID.is_city(coord):
			var city = W_GRID.get_city(coord)
			if city.controller == current_player:
				if world_move_info.enter_city:
					if not hero.has_movement_points():
						print("not enough movement points")
						return
					print("moving ", hero," to ",coord)
					do_local_hero_move(hero, coord)
					hero.spend_movement_point()
				else:
					# CITY TRADE
					trade_city(city, hero)
					return

		if W_GRID.has_army(coord):
			var army = W_GRID.get_army(coord)
			if current_player == army.controller:
				# ARMY TRADE
				trade_armies(army)
			return

		if W_GRID.is_movable(coord):
			if not hero.has_movement_points():
				print("not enough movement points")
				return
			print("moving ", hero," to ",coord)
			do_local_hero_move(hero, coord)
			hero.spend_movement_point()

	elif world_move_info.move_type == WorldMoveInfo.TYPE_RECRUIT_HERO:
		var player : Player = get_player_by_index(world_move_info.recruit_hero_info.player_index)
		var hero_data : DataHero = world_move_info.recruit_hero_info.data_hero
		var coord : Vector2i = world_move_info.target_tile_coord
		# TODO check values and make desync when something is wrong
		do_local_recruit_hero(player, hero_data, coord)
	elif world_move_info.move_type == WorldMoveInfo.TYPE_RECRUIT_UNIT:
		var coord : Vector2i = world_move_info.target_tile_coord
		var unit : DataUnit = world_move_info.data
		do_local_recruit_unit(coord, unit)
	elif world_move_info.move_type == WorldMoveInfo.TYPE_BUILD:
		var city_coord : Vector2i = world_move_info.target_tile_coord
		var building : DataBuilding = world_move_info.data
		do_local_build(city_coord, building)
	elif world_move_info.move_type == WorldMoveInfo.TYPE_END_TURN:
		do_local_end_the_turn()
	else:
		assert(false, "Move %s not supported in perform_world_move_info" % \
			world_move_info.move_type)
	world_move_done.emit()


func win_game(player: Player):
	world_ui.show_you_win(player)


func perform_network_move(world_move_info : WorldMoveInfo) -> void:
	perform_world_move_info(world_move_info)


#endregion


#region City Management


func trade_city(city : City, hero : ArmyForm):
	print("trade_city")
	hero.entity.heal_in_city()
	world_ui.show_trade_ui(city, hero)


func request_recruit_unit(hero_army : ArmyForm, unit : DataUnit):
	var world_move_info = WorldMoveInfo.make_recruit_unit(hero_army.coord, unit)

	if not NET.client:
		WM.perform_world_move_info(world_move_info)
	else:
		NET.client.queue_request_world_move(world_move_info)


func request_recruit_hero(player : Player, hero_data : DataHero, \
		coord : Vector2i) -> void:
	var world_move_info = WorldMoveInfo.make_recruit_hero( \
		get_player_index(player),
		hero_data,
		coord)
	if not NET.client:
		perform_world_move_info(world_move_info)
	else:
		NET.client.queue_request_world_move(world_move_info)


func request_build(city : City, building_data : DataBuilding) -> void:
	var world_move_info = WorldMoveInfo.make_build(city.coord, building_data)
	if not NET.client:
		perform_world_move_info(world_move_info)
	else:
		NET.client.queue_request_world_move(world_move_info)


func do_local_recruit_hero(player : Player, hero_data : DataHero, \
		coord : Vector2i) -> void:
	var army_for_world_map : ArmyForm = \
		ArmyForm.create_hero_army(player, hero_data)

	var cost = player.get_hero_cost(hero_data)
	if not player.purchase(cost):
		print("not enough cash, needed ", cost)
		return

	add_child(army_for_world_map)
	player.hero_recruited(army_for_world_map)

	# FIXME drut, adding hero unit to the army
	var hero_unit = army_for_world_map.entity.hero.data_unit
	army_for_world_map.entity.units_data.append(hero_unit)

	W_GRID.place_army(army_for_world_map, coord)


func do_local_recruit_unit(coord : Vector2i, unit : DataUnit) -> void:
	var hero_army : ArmyForm = W_GRID.get_army(coord)
	if not hero_army or not unit:
		NET.desync()
	if hero_army.controller.purchase(unit.cost):
		hero_army.entity.units_data.append(unit)
	else:
		push_error("not enough cash, needed %s" % unit.cost)
		NET.desync()


func do_local_build(city_coord : Vector2i, \
		building_data : DataBuilding) -> void:
	var city = W_GRID.get_city(city_coord)
	if not city:
		NET.desync()
	city.build(building_data)


#endregion


#region Battles

func start_combat( \
		armies : Array[Army], \
		combat_coord : Vector2i, \
		battle_state : SerializableBattleState):
	"""
	Starts a battle using Battle Manager (BM)
	"""
	print("start_combat")
	var biggest_army_size : int = 0
	for army in armies:
		var army_size : int = army.units_data.size()
		if biggest_army_size < army_size:
			biggest_army_size = army_size
	combat_tile = combat_coord
	var battle_map : DataBattleMap = W_GRID.get_battle_map(combat_tile, biggest_army_size)
	var x_offset = get_bounds_global_position().end.x + CFG.MAPS_OFFSET_X
	BM.start_battle(armies, battle_map, battle_state, x_offset)
	UI.switch_camera()


## shortcut to start battle when one army attacks another
func start_combat_by_attack(attacking_army : ArmyForm, coord : Vector2i):
	print("start_combat")

	var armies : Array[Army] = [
		attacking_army.entity,
		W_GRID.get_army(coord).entity,
	]
	start_combat(armies, coord, null)


func end_of_battle(battle_results : Array[BattleGridState.ArmyInBattleState]):
	#TODO get result from Battle Manager
	const ATTACKER = 0
	const DEFENDER = 1

	var attack_army : Army = battle_results[ATTACKER].army_reference
	var defence_army : Army = battle_results[DEFENDER].army_reference
	var attack_hero = attack_army.hero
	var defence_hero = defence_army.hero
	var attack_army_form = W_GRID.get_army(attack_army.coord)
	if attack_hero:
		attack_hero.add_xp_for_casualties(battle_results[DEFENDER].dead_units, defence_hero)
	if defence_hero:
		defence_hero.add_xp_for_casualties(battle_results[ATTACKER].dead_units, attack_hero)

	if battle_results[ATTACKER].can_fight():
		print("attacker won")
		kill_army(W_GRID.get_army(combat_tile)) # clear the tile of enemy presence
		attack_army.apply_losses(battle_results[ATTACKER].dead_units)
		do_local_hero_move(attack_army_form, combat_tile)
		attack_army_form.spend_movement_point()
	else:
		kill_army(attack_army_form)  # clear the tile where attack_army_form was
		set_selected_hero(null)
		print("hero died")
		var defender_army = W_GRID.get_army(combat_tile)
		defender_army.apply_losses(battle_results[DEFENDER].dead_units)
	UI.go_to_custom_ui(world_ui)


func kill_army(army : ArmyForm):
	if army.entity.hero:
		army.controller.hero_died(army.entity.hero)
	W_GRID.remove_army(army) # there can only be one army at a single tile
	army.queue_free()
	world_ui.city_ui._refresh_all()

# endregion


#region World End

func close_world():
	players = []
	combat_tile = Vector2i.MAX
	selected_hero = null
	current_player = null

	for hero in get_children():
		hero.queue_free()

	W_GRID.reset_data()

#endregion


#region World Setup

func spawn_world_ui():
	world_ui = load("res://Scenes/UI/WorldUi.tscn").instantiate()
	UI.add_custom_screen(world_ui)


func start_new_world(world_map : DataWorldMap) -> void:
	BM.world_map_started()

	var spawn_location = world_map.get_spawn_locations()

	for coord in spawn_location:
		print("spawn: ",  coord)

	players = IM.players

	assert(players.size() != 0, "ERROR WM.players is empty")

	current_player = players[0]
	if world_ui == null or not is_instance_valid(world_ui):
		spawn_world_ui()
	UI.go_to_custom_ui(world_ui)
	world_ui.game_started()

	W_GRID.load_map(world_map, false)

	for player_id in range(players.size()):
		spawn_player(spawn_location[player_id], players[player_id])

	world_ui.show_trade_ui(current_player.capital_city, null)
	world_ui.refresh_heroes(current_player)


# this function probably should be divided into parts
func start_world_in_state(world_map : DataWorldMap, \
		world_state : SerializableWorldState) -> void:
	_batch_mode = true

	BM.world_map_started()

	players = IM.players

	assert(players.size() != 0, "ERROR WM.players is empty")


	W_GRID.load_map(world_map, true)
	for coord in world_state.place_hexes:
		var ser = world_state.place_hexes[coord]

		# these are a HACK and TEMP
		# TODO rework Place and make it nice
		var tile_placed_by_loading_map : TileForm = W_GRID.get_tile_form(coord)
		var player : Player = get_player_by_index(ser["player"])
		var place : Place = tile_placed_by_loading_map.place
		place.controller = player
		if place is City:
			var city = place as City
			for building in ser["buildings"]:
				var building_data = DataBuilding.from_network_id(building)
				city.buildings.append(building_data)
			if player:
				player.cities.append(city)
			# we do not add cities yet as they are added at map load
			# maybe it will change in the future
		elif place is HuntSpot:
			var hunt_spot = place as HuntSpot
			var goods_array = ser["present_goods"]
			hunt_spot._present_goods = \
				Goods.new(goods_array[0], goods_array[1], goods_array[2])
			hunt_spot.current_level = ser["current_level"]
			hunt_spot._alive_army = W_GRID.get_army_form(coord)
			hunt_spot._time_left_for_respawn = ser["time_to_respawn"]
		elif place is Outpost:
			pass
		# Deposit is not used anywhere

	for coord in world_state.unit_hexes:
		var ser = world_state.unit_hexes[coord]
		var unit : ArmyForm = _deserialize_unit_hex(ser, coord)
		add_child(unit)
		W_GRID.place_army(unit, coord)
		if unit.controller and unit.entity.hero:
			unit.controller.hero_armies.append(unit)
		# here we also do a small HACK that if hero is not in town, we he set
		# him not to be selected -- then he will get his light background back
		if not W_GRID.get_place(unit.coord) is City and unit.entity.hero:
			unit.set_selected(false)

	for player_index in players.size():
		var player : Player = players[player_index]
		if player.cities.size() > 0:
			var capital_coord = world_state.capital_cities[player_index]
			if player.cities[0].coord != capital_coord:
				# swap
				var index = player.cities.find(capital_coord)
				if index > 0:
					var copy = player.cities[0]
					player.cities[0] = player.cities[index]
					player.cities[index] = copy
		var goods = world_state.goods.slice( \
			3 * player_index, 3 * (player_index + 1))
		player.goods = Goods.new(goods[0], goods[1], goods[2])
		for dead_hero in world_state.dead_heroes[player_index]:
			var hero := Hero.from_network_serializable(dead_hero, player)
			player.dead_heroes.append(hero)
		for outpost_coord in world_state.outposts[player_index]:
			var outpost : Place = W_GRID.get_place(outpost_coord)
			assert(outpost is Outpost)
			player.outposts.append(outpost)
		for outpost_building in world_state.outpost_buildings[player_index]:
			var building_data : DataBuilding = \
				DataBuilding.from_network_id(outpost_building)
			player.outpost_buildings.append(building_data)

	current_player = players[world_state.current_player]

	# TODO some cheks for these inputs

	if world_ui == null or not is_instance_valid(world_ui):
		spawn_world_ui()
	UI.go_to_custom_ui(world_ui)
	world_ui.refresh_player_buttons()

	world_ui.show_trade_ui(current_player.capital_city, null)

	_batch_mode = false


func spawn_player(coord : Vector2i, player : Player):
	var capital_city = W_GRID.get_city(coord)
	player.set_capital(capital_city)

#endregion


func _get_serializable_unit_hex(hex : ArmyForm) -> Dictionary:
	var army : Army = hex.entity
	var army_dict : Dictionary = {}
	army_dict["player"] = get_player_index(army.controller)

	if army.hero:
		var hero : Hero = army.hero
		army_dict["hero"] = hero.to_network_serializable()

	army_dict["units"] = []
	var unit_array = army_dict["units"]
	for unit in army.units_data:
		unit_array.append(DataUnit.get_network_id(unit))

	return army_dict


func _get_serializable_place_hex(hex : Place) -> Dictionary:
	return Place.get_network_serializable(hex)


# TODO consider moving to army_form.gd and deduplicate some code
func _deserialize_unit_hex(hex : Dictionary, coord : Vector2i) -> ArmyForm:
	var army := Army.new()
	var army_form := CFG.DEFAULT_ARMY_FORM.instantiate()
	var player : Player = get_player_by_index(hex["player"])
	var tile_form = W_GRID.get_tile_form(coord)
	army.coord = coord
	army.controller = player
	army_form.entity = army
	if "hero" in hex:
		army.hero = Hero.from_network_serializable(hex["hero"], player)
	for unit in hex["units"]:
		var data_unit = DataUnit.from_network_id(unit)
		army.units_data.append(data_unit)
	army_form.position = tile_form.position
	if army.hero:
		army_form.get_node("sprite_unit").texture = \
			load(army.hero.template.data_unit.texture_path)
	else:
		if army.units_data.size() > 0:
			var shown_unit : DataUnit = army.units_data[0]
			var sprite = army_form.get_node("sprite_unit")
			sprite.texture = load(shown_unit.texture_path)
			sprite.scale = Vector2(0.9, 0.9)
			army_form.get_node("MoveLabel").text = ""
			army_form.get_node("DescriptionLabel").text = ""

	return army_form


func get_serializable_state() -> SerializableWorldState:
	var state := SerializableWorldState.new()
	if W_GRID.unit_grid:
		var hexes = W_GRID.unit_grid.hexes
		for row_index in hexes.size():
			var row = hexes[row_index]
			for hex_index in row.size():
				var hex = row[hex_index]
				if hex:
					var ser = _get_serializable_unit_hex(hex)
					state.unit_hexes[Vector2i(row_index, hex_index)] = ser
	if W_GRID.places_grid:
		# TODO this part should probably send networkd IDs of hex tiles and
		# their current state (things that are not set at start)
		var hexes = W_GRID.places_grid.hexes
		for row_index in hexes.size():
			var row = hexes[row_index]
			for hex_index in row.size():
				var hex = row[hex_index]
				if hex:
					var ser = _get_serializable_place_hex(hex)
					state.place_hexes[Vector2i(row_index, hex_index)] = ser
	for player in players:
		state.goods.append(player.goods.wood)
		state.goods.append(player.goods.iron)
		state.goods.append(player.goods.ruby)
		if player.capital_city:
			state.capital_cities.append(player.capital_city.coord)
		else:
			state.capital_cities.append(Vector2i.MAX) # no optional vector :c
		state.dead_heroes.append([])
		var dh = state.dead_heroes.back()
		for dead_hero in player.dead_heroes:
			dh.append(dead_hero.to_network_serializable())
		state.outposts.append([])
		var o = state.outposts.back()
		for outpost in player.outposts:
			o.append(outpost.coord)
		state.outpost_buildings.append([])
		var ob = state.outpost_buildings.back()
		for outpost_building in player.outpost_buildings:
			ob.append(DataBuilding.get_network_id(outpost_building))
	state.current_player = WM.get_player_index(current_player)
	return state
