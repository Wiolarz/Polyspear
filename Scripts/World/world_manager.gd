# Singleton - WM
extends GridNode2D

signal world_move_done




var world_ui : WorldUI = null

## Only army that has a hero can move (army can only have a single hero)
var selected_hero : ArmyForm

# TODO movew to world state chyba
var combat_tile : Vector2i

var _batch_mode : bool = false

var tile_grid : Node2D = null
var armies : Node2D = null

var _is_world_game_active : bool = false

#region Start World

func _ready() -> void:

	world_ui = load("res://Scenes/UI/WorldUi.tscn").instantiate()

	tile_grid = Node2D.new()
	tile_grid.name = "GRID"
	add_child(tile_grid)
	armies = Node2D.new()
	armies.name = "ARMIES"
	add_child(armies)

	UI.add_custom_screen(world_ui)

#endregion Start World


#region helpers



## Camera bounds
func get_bounds_global_position() -> Rect2:
	#if not WS: #TEMP
	#	push_warning("asking not initialized grid for camera bounding box")
	#	return Rect2(0, 0, 0, 0)
	var top_left_hex = WS.get_top_left_hex()
	var bottom_right_hex = WS.get_bottom_right_hex()
	var top_left_tile_form : TileForm = get_tile_of_hex(top_left_hex)
	var bottom_right_tile_form : TileForm = get_tile_of_hex(bottom_right_hex)
	var size : Vector2 = \
		bottom_right_tile_form.global_position - \
		top_left_tile_form.global_position
	return Rect2(top_left_tile_form.global_position, size)


func get_current_player_capital() -> City:
	var player_state = WS.get_player_by_index(WS.current_player_index)
	if not player_state:
		return null
	return player_state.capital_city


func world_game_is_active() -> bool:
	return _is_world_game_active

#endregion helpers


#region Main functions

func set_selected_hero(army : Army):
	print("selected ", army)
	if selected_hero:
		selected_hero.set_selected(false)
		# var city = get_current_player_capital()
		# assert(city)
		# world_ui.show_trade_ui(city)
	var army_form : ArmyForm = get_army_form(army)
	selected_hero = army_form
	if selected_hero:
		selected_hero.set_selected(true)
	world_ui.refresh_heroes()
	world_ui.city_ui._refresh_units_to_buy()
	world_ui.city_ui._refresh_army_display()


func get_current_player() -> Player:
	var index : int = WS.current_player_index
	return IM.get_player_by_index(index)


func end_turn():
	var world_move_info = WorldMoveInfo.make_end_turn()
	try_do_move(world_move_info)


func callback_turn_changed():
	set_selected_hero(null)
	world_ui.refresh_heroes()
	world_ui.show_trade_ui(get_current_player_capital())
	world_ui.refresh_player_buttons()


## this function may be temporary, the sure thing is it needs to be made better
func get_army_form(army : Army) -> ArmyForm:
	for army_form in armies.get_children():
		if army_form.entity == army:
			return army_form
	return null


## this function may be temporary, the sure thing is it needs to be made better
func get_tile_of_hex(hex : WorldHex) -> Node2D:
	for tile_form in tile_grid.get_children():
		if tile_form.hex == hex:
			return tile_form
	return null

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
	var selection = WS.get_interactable_at(coord)
	var city = WS.get_city_at(coord)
	var army = WS.get_army_at(coord)
	if army:
		if WS.current_player_index == selection.controller_index:
			set_selected_hero(army)

	if city:
		if city.controller_index == WS.current_player_index:
			if not army:
				world_ui.city_ui.show_recruit_heroes()
			else:
				world_ui.city_ui.show_recruit_units()


func try_interact(hero : ArmyForm, coord : Vector2i):
	var start_coords = hero.coord
	var city = WS.get_city_at(coord)
	if city and city.controller_index == hero.entity.controller_index: # we start trade instead of travel
		# there is separate button to move to city
		trade_city(city)
		return
	var world_move_info := \
		WorldMoveInfo.make_world_travel(start_coords, coord)
	try_do_move(world_move_info)


## called on input from player
func try_do_move(world_move_info : WorldMoveInfo) -> void:
	var problem = WS.check_move_allowed(world_move_info)
	if problem != "":
		print(problem)
		return
	if not NET.client:
		perform_world_move_info(world_move_info)
	else:
		NET.client.queue_request_world_move(world_move_info)


## STUB
func trade_armies(_second_army : ArmyForm):
	print("trading armies")


## called by `try_do_move` or when move is received from network
func perform_world_move_info(world_move_info : WorldMoveInfo) -> void:
	print(NET.get_role_name(), " performing world move ", world_move_info)
	# TODO replay.record_move
	# TODO replay.save
	if NET.server:
		NET.server.broadcast_world_move(world_move_info)
	var success = WS.do_move(world_move_info)
	if not success:
		NET.desync()
		return
	world_move_done.emit()


func win_game(player : Player):
	world_ui.show_you_win(player)


func perform_network_move(world_move_info : WorldMoveInfo) -> void:
	perform_world_move_info(world_move_info)


#endregion


#region City Management


func trade_city(city : City):
	print("trade_city")
	# TODO revwert this in world state
	# hero.heal_in_city()
	world_ui.show_trade_ui(city)


func try_recruit_unit(city_coord : Vector2i, army_coord : Vector2i,
		unit : DataUnit):
	var world_move_info = \
		WorldMoveInfo.make_recruit_unit(city_coord, army_coord, unit)
	try_do_move(world_move_info)


func try_recruit_hero(city : City, hero_data : DataHero) -> void:
	var world_move_info = WorldMoveInfo.make_recruit_hero( \
		city.controller_index,
		hero_data,
		city.coord)
	try_do_move(world_move_info)


func request_build(city : City, building_data : DataBuilding) -> void:
	var world_move_info = WorldMoveInfo.make_build(city.coord, building_data)
	if not NET.client:
		perform_world_move_info(world_move_info)
	else:
		NET.client.queue_request_world_move(world_move_info)


func do_local_travel(source : Vector2i, target : Vector2i) -> void:
	var success : bool = WS.army_travel(source, target)

	if not success:
		NET.desync()
		return

#endregion


#region Battles

func start_combat( \
		armies_ : Array[Army], \
		combat_coord : Vector2i, \
		battle_state : SerializableBattleState = null):
	"""
	Starts a battle using Battle Manager (BM)
	"""
	print("start_combat")
	#TODO verify with design if biggest army size code is needed
	var biggest_army_size : int = 0
	for army in armies_:
		var army_size : int = army.units_data.size()
		if biggest_army_size < army_size:
			biggest_army_size = army_size
	
	# Swap neutral armies with different play controllers
	# We assume that battles involving neutrals cannot contain number of unique team armies equal to number of teams in the game
	#counting unique teams
	var teams_present_in_battle : Array[int] = []
	for army in armies_:
		# neutral armies don't have army controller and they are neutral
		# if more than two neutral armies are present in battle they oppose eachother
		if army.controller and army.controller.team not in teams_present_in_battle:
			teams_present_in_battle.append(army.controller.team)
		
	
	#assigning players to control neutrals
	var player_idx_to_control_neutral : int = WS.current_player_index
	for army in armies_:
		if army.controller: # we search only for neutral armies
			continue
		while not army.controller:
			player_idx_to_control_neutral -= 1  # we look for previous player to play as neutrals
			if player_idx_to_control_neutral == -1:  # Search from the end
				player_idx_to_control_neutral = WS.player_states.size() - 1
			# no need to verify if player has been assigned, as each neutral has to be controlled by unique team anyway.
			var player : Player = WS.player_states[player_idx_to_control_neutral].controller
			if player.team not in teams_present_in_battle:
				#TODO refactor armies so that we have clear seperation from checking who can attack who, and who gets to control those units. Current getter for controller from faction may not be correct
				army.faction = WS.player_states[player_idx_to_control_neutral] # Setting up the player to control the army
				army.controller_index = player_idx_to_control_neutral # TEMP
				teams_present_in_battle.append(player.team)


	
	combat_tile = combat_coord
	var battle_map : DataBattleMap = WS.get_battle_map_at(combat_tile, biggest_army_size)
	var x_offset = get_bounds_global_position().end.x + CFG.MAPS_OFFSET_X
	BM.start_battle(armies_, battle_map, x_offset, battle_state)
	UI.switch_camera()


func end_of_battle(battle_results : Array[BattleGridState.ArmyInBattleState]):

	WS.end_combat(battle_results)

	UI.go_to_custom_ui(world_ui)


# endregion


#region World End

func close_world():
	_is_world_game_active = false
	combat_tile = Vector2i.MAX
	selected_hero = null

	for army_form in armies.get_children():
		army_form.queue_free()
	for tile in tile_grid.get_children():
		tile.queue_free()


#endregion


#region World Setup

func spawn_world_ui():
	world_ui = load("res://Scenes/UI/WorldUi.tscn").instantiate()
	UI.add_custom_screen(world_ui)


func start_new_world(world_map : DataWorldMap) -> void:

	_is_world_game_active = true

	WS.create(world_map, IM.game_setup_info.slots)

	recreate_tile_forms()
	recreate_army_forms()

	UI.go_to_custom_ui(world_ui)
	world_ui.game_started()

	world_ui.show_trade_ui(get_current_player_capital())
	world_ui.refresh_heroes()


#STUB
# this function probably should be divided into parts
func start_world_in_state(world_map : DataWorldMap, \
		serializable_WS : SerializableWorldState) -> void:

	_is_world_game_active = true

	# TODO probably check serializable_WS not null

	_batch_mode = true

	_batch_mode = true

	WS.create(
		world_map, IM.game_setup_info.slots, serializable_WS)

	recreate_tile_forms()
	recreate_army_forms()

	UI.go_to_custom_ui(world_ui)
	world_ui.game_started()

	world_ui.show_trade_ui(get_current_player_capital())
	world_ui.refresh_heroes()

	_batch_mode = false





func spawn_player(coord : Vector2i, player : Player):
	var capital_city = WS.get_city_at(coord)
	player.set_capital(capital_city)

#endregion

func recreate_tile_forms() -> void:
	Helpers.remove_all_children(tile_grid)
	for x in range(WS.grid.width):
		for y in range(WS.grid.height):
			var coord := Vector2i(x, y)
			var hex : WorldHex = WS.grid.get_hex(coord)
			var tile : TileForm = TileForm.create_world_tile_new(hex, coord, \
				to_position(coord))
			tile_grid.add_child(tile)


func recreate_army_forms() -> void:
	Helpers.remove_all_children(armies)
	for x in range(WS.grid.width):
		for y in range(WS.grid.height):
			var coord := Vector2i(x, y)
			var hex : WorldHex = WS.grid.get_hex(coord)
			if not hex.army:
				continue
			var new_position = to_position(coord)
			var army_form : ArmyForm = ArmyForm.create_form_of_army(hex, \
				new_position)
			armies.add_child(army_form)


func _refresh_army_form_position(army_form : ArmyForm) -> void:
	army_form.position = to_position(army_form.entity.coord)


func get_serializable_state() -> SerializableWorldState:
	var state := SerializableWorldState.new()
	if WS:
		state = WS.to_network_serializable()
	return state


#region callbacks

func callback_player_created(_player : Player) -> void:
	return # does nothing yet -- TODO add something or delete in future


func callback_army_created(army : Army) -> void:
	var coord = army.coord
	var hex = WS.grid.get_hex(coord)
	var new_position = to_position(coord)
	var army_form : ArmyForm = ArmyForm.create_form_of_army(hex, \
		new_position)
	armies.add_child(army_form)


## TODO make it full update, along with imgae etc.
## now bo mi się nie chce it is only position :>
func callback_army_updated(army : Army) -> void:
	callback_army_moved(army)


func callback_army_moved(army : Army) -> void:
	var army_form = get_army_form(army)
	_refresh_army_form_position(army_form)


func callback_army_destroyed(army : Army) -> void:
	var army_form = get_army_form(army)
	if selected_hero == army_form:
		set_selected_hero(null)
	army_form.queue_free()


func callback_place_changed(coord : Vector2i) -> void:
	var _hex = WS.grid.get_hex_at(coord)
	return


func callback_combat_started(armies_ : Array, coord_ : Vector2i) -> void:
	start_combat(armies_, coord_)


#endregion


#region cheats


func cheat_money(new_wood : int = 100, new_iron : int = 100, new_ruby : int = 100) -> void:
	# Add goods to the player
	WS.player_states[WS.current_player_index]._goods.add(
		Goods.new(new_wood, new_iron, new_ruby)
	)


func hero_speed_cheat(speed : int = 100) -> void:
	if not selected_hero:
		print("no selected hero")
		return
	# Add movement points to a hero
	WM.selected_hero.entity.hero.movement_points += speed


func hero_level_up(levels : int = 1) -> void:
	if not selected_hero:
		print("no selected hero")
		return
	# Level up hero n times
	for i in range(levels):
		selected_hero.entity.hero._level_up()
	# After leveling up xp is a negative value
	selected_hero.entity.hero.xp = 0


func city_upgrade_cheat() -> void:
	var current_player : Faction = WS.get_current_player()

	# Iterate over every race building
	for building in current_player.race.buildings:
		# Copied from build_building function
		if not building.is_outpost_building():
			world_ui.city_ui.city.buildings.append(building)
		else:
			current_player.outpost_buildings.append(building)
	# Update UI
	world_ui.city_ui._refresh_buildings_display()


#endregion
