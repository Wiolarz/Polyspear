# Singleton - WM
extends GridNode2D

signal world_move_done


#region Variables
var world_state : WorldState = null
var world_ui : WorldUI = null

## Only army that has a hero can move (army can only have a single hero)
var selected_hero : ArmyForm

# TODO movew to world state chyba
var combat_tile : Vector2i

var _batch_mode : bool = false

var tile_grid : Node2D = null
var armies : Node2D = null

#endregion


func _ready() -> void:

	world_ui = load("res://Scenes/UI/WorldUi.tscn").instantiate()

	tile_grid = Node2D.new()
	tile_grid.name = "GRID"
	add_child(tile_grid)
	armies = Node2D.new()
	armies.name = "ARMIES"
	add_child(armies)

	UI.add_custom_screen(world_ui)


#region helpers


func world_game_is_active() -> bool:
	return world_state != null


func get_bounds_global_position() -> Rect2:
	if not world_state:
		push_warning("asking not initialized grid for camera bounding box")
		return Rect2(0, 0, 0, 0)
	var top_left_hex = world_state.get_top_left_hex()
	var bottom_right_hex = world_state.get_bottom_right_hex()
	var top_left_tile_form : TileForm = get_tile_of_hex(top_left_hex)
	var bottom_right_tile_form : TileForm = get_tile_of_hex(bottom_right_hex)
	var size : Vector2 = \
		bottom_right_tile_form.global_position - \
		top_left_tile_form.global_position
	return Rect2(top_left_tile_form.global_position, size)


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


func get_current_player_capital() -> City:
	if not world_state:
		return null
	var player_state = world_state.get_player(world_state.current_player_index)
	if not player_state:
		return null
	return player_state.capital_city


#endregion # helpers


#region Main functions

#
func get_index_of_player(player : Player) -> int:
	return IM.get_index_of_player(player)


func get_player_by_index(index : int) -> Player:
	return IM.get_player_by_index(index)


func get_current_player() -> Player:
	if not world_state:
		return null
	var index : int = world_state.current_player_index
	return get_player_by_index(index)


func try_end_turn():
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
	if not world_state:
		return null
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
	var selection = world_state.get_interactable_at(coord)
	var city = world_state.get_city_at(coord)
	var army = world_state.get_army_at(coord)
	if army:
		if world_state.current_player_index == selection.controller_index:
			set_selected_hero(army)

	if city:
		if city.controller_index == world_state.current_player_index:
			if not army:
				world_ui.city_ui.show_recruit_heroes()
			else:
				world_ui.city_ui.show_recruit_units()



func try_interact(hero : ArmyForm, coord : Vector2i):
	var start_coords = hero.coord
	var city = world_state.get_city_at(coord)
	if city: # we start trade instead of travel
		# there is separate button to move to city
		trade_city(city)
		return
	var world_move_info := \
		WorldMoveInfo.make_world_travel(start_coords, coord)
	try_do_move(world_move_info)


## called on input from player
func try_do_move(world_move_info : WorldMoveInfo) -> void:
	var problem = world_state.check_move_allowed(world_move_info)
	if problem != "":
		print(problem)
		return
	if not NET.client:
		perform_world_move_info(world_move_info)
	else:
		NET.client.queue_request_world_move(world_move_info)


func trade_armies(_second_army : ArmyForm):
	#TODO
	print("trading armies")


## called by `try_do_move` or when move is received from network
func perform_world_move_info(world_move_info : WorldMoveInfo) -> void:
	print(NET.get_role_name(), " performing world move ", world_move_info)
	# TODO replay.record_move
	# TODO replay.save
	if NET.server:
		NET.server.broadcast_world_move(world_move_info)
	var success = world_state.do_move(world_move_info)
	if not success:
		NET.desync()
		return
	world_move_done.emit()


func win_game(player: Player):
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
	var success : bool = world_state.army_travel(source, target)

	if not success:
		NET.desync()
		return



func do_local_recruit_hero(player : Player, hero_data : DataHero, \
		coord : Vector2i) -> void:

	var army = world_state.recruit_hero(hero_data, coord)

	if not army:
		NET.desync()
		return

	armies.add_child(ArmyForm.create_form_of_army(
		world_state.grid.get_hex(coord),
		coord,
		to_position(coord)
	))


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
	var battle_map : DataBattleMap = world_state.get_battle_map_at(combat_tile, biggest_army_size)
	var x_offset = get_bounds_global_position().end.x + CFG.MAPS_OFFSET_X
	BM.start_battle(armies, battle_map, battle_state, x_offset)
	UI.switch_camera()


## shortcut to start battle when one army attacks another
func start_combat_by_attack(attacking_army : Army, coord : Vector2i):
	print("start_combat")

	var armies : Array[Army] = [
		attacking_army,
		world_state.get_army_at(coord),
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

	var updates : Array[Dictionary] = [
		{ "army": attack_army, },
		{ "army": defence_army, },
	]

	# if attack_hero:
	# 	attack_hero.add_xp_for_casualties(battle_results[DEFENDER].dead_units, defence_hero)
	# if defence_hero:
	# 	defence_hero.add_xp_for_casualties(battle_results[ATTACKER].dead_units, attack_hero)

	var the_range = range(min(updates.size(), battle_results.size()))
	for i in the_range:
		var update = updates[i]
		var result = battle_results[i]
		var hero = result.army_reference.hero
		var level = 1
		if hero:
			level = hero.level
		update["losses"] = result.dead_units
		update["killed"] = not result.can_fight()
		# xp
		var xp = 0
		for j in the_range:
			if j == i:
				continue
			var opposite_result = battle_results[j]
			var deads = opposite_result.dead_units
			for dead in deads:
				if dead.level >= level:
					xp += 1
			var opposite_hero = opposite_result.army_reference.hero
			if opposite_hero and opposite_hero.level >= level:
				xp += 1
		update["xp"] = xp

	if battle_results[DEFENDER].can_fight():
		# no matter what, if defender is alive, it is draw of defender won
		# that means attaked dead
		updates[ATTACKER]["killed"] = true

	world_state.end_combat(updates)

	UI.go_to_custom_ui(world_ui)


# func kill_army(army : Army):
# 	if army.hero:
# 		army.controller.hero_died(army.hero)
# 	world_state.remove_army(army) # there can only be one army at a single tile
# 	# army.queue_free()
# 	world_ui.city_ui._refresh_all()

# endregion


#region World End

func close_world():
	combat_tile = Vector2i.MAX
	selected_hero = null

	for army_form in armies.get_children():
		army_form.queue_free()
	for tile in tile_grid.get_children():
		tile.queue_free()

	_clear_state()

#endregion


#region World Setup

func spawn_world_ui():
	world_ui = load("res://Scenes/UI/WorldUi.tscn").instantiate()
	UI.add_custom_screen(world_ui)


func start_new_world(world_map : DataWorldMap) -> void:
	BM.world_map_started()

	_clear_state()
	world_state = WorldState.create(world_map, IM.game_setup_info.slots, null)
	_connect_callbacks()
	world_ui.refresh_world_state_ugly(world_state)

	recreate_tile_forms()
	recreate_army_forms()

	UI.go_to_custom_ui(world_ui)
	world_ui.game_started()

	world_ui.show_trade_ui(get_current_player_capital())
	world_ui.refresh_heroes()


# this function probably should be divided into parts
func start_world_in_state(world_map : DataWorldMap, \
		ser_state : SerializableWorldState) -> void:

	# TODO probably check ser_state not null

	_batch_mode = true

	BM.world_map_started()

	_clear_state()
	world_state = WorldState.create(world_map, IM.game_setup_info.slots, ser_state)
	_connect_callbacks()
	world_ui.refresh_world_state_ugly(world_state)

	recreate_tile_forms()
	recreate_army_forms()

	UI.go_to_custom_ui(world_ui)
	world_ui.game_started()

	world_ui.show_trade_ui(get_current_player_capital())
	world_ui.refresh_heroes()

	_batch_mode = false


func _connect_callbacks() -> void:
	world_state.player_created.connect(callback_player_created)
	world_state.army_created.connect(callback_army_created)
	world_state.army_updated.connect(callback_army_updated)
	world_state.army_moved.connect(callback_army_moved)
	world_state.army_destroyed.connect(callback_army_destroyed)
	world_state.place_changed.connect(callback_place_changed)
	world_state.combat_started.connect(callback_combat_started)
	world_state.turn_changed.connect(callback_turn_changed)


func _clear_state() -> void:
	if not world_state:
		return
	world_state.player_created.disconnect(callback_player_created)
	world_state.army_created.disconnect(callback_army_created)
	world_state.army_updated.disconnect(callback_army_updated)
	world_state.army_moved.disconnect(callback_army_moved)
	world_state.army_destroyed.disconnect(callback_army_destroyed)
	world_state.place_changed.disconnect(callback_place_changed)
	world_state.combat_started.disconnect(callback_combat_started)
	world_state.turn_changed.disconnect(callback_turn_changed)
	world_state = null


func spawn_player(coord : Vector2i, player : Player):
	var capital_city = world_state.get_city_at(coord)
	player.set_capital(capital_city)

#endregion

func recreate_tile_forms() -> void:
	Helpers.remove_all_children(tile_grid)
	for x in range(world_state.grid.width):
		for y in range(world_state.grid.height):
			var coord := Vector2i(x, y)
			var hex : WorldHex = world_state.grid.get_hex(coord)
			var tile : TileForm = TileForm.create_world_tile_new(hex, coord, \
				to_position(coord))
			tile_grid.add_child(tile)


func recreate_army_forms() -> void:
	Helpers.remove_all_children(armies)
	for x in range(world_state.grid.width):
		for y in range(world_state.grid.height):
			var coord := Vector2i(x, y)
			var hex : WorldHex = world_state.grid.get_hex(coord)
			if not hex.army:
				continue
			var new_position = to_position(coord)
			var army_form : ArmyForm = ArmyForm.create_form_of_army(hex, \
				coord, new_position)
			armies.add_child(army_form)


func _refresh_army_form_position(army_form : ArmyForm) -> void:
	army_form.position = to_position(army_form.entity.coord)


# func _get_serializable_place_hex(hex : Place) -> Dictionary:
# 	return Place.get_network_serializable(hex)


## TODO consider moving to army_form.gd and deduplicate some code
#func _deserialize_unit_hex(hex : Dictionary, coord : Vector2i) -> ArmyForm:
	#var army := Army.new()
	#var army_form := CFG.DEFAULT_ARMY_FORM.instantiate()
	#var player : Player = get_player_by_index(hex["player"])
	#var tile_form : TileForm = get_tile_of_hex(world_state.get_tile_form(coord))
	#army.coord = coord
	#army.controller = player
	#army_form.entity = army
	#if "hero" in hex:
		#army.hero = Hero.from_network_serializable(hex["hero"], player)
	#for unit in hex["units"]:
		#var data_unit = DataUnit.from_network_id(unit)
		#army.units_data.append(data_unit)
	#army_form.position = tile_form.position
	#if army.hero:
		#army_form.get_node("sprite_unit").texture = \
			#load(army.hero.template.data_unit.texture_path)
	#else:
		#if army.units_data.size() > 0:
			#var shown_unit : DataUnit = army.units_data[0]
			#var sprite = army_form.get_node("sprite_unit")
			#sprite.texture = load(shown_unit.texture_path)
			#sprite.scale = Vector2(0.9, 0.9)
			#army_form.get_node("MoveLabel").text = ""
			#army_form.get_node("DescriptionLabel").text = ""
#
	#return army_form


func get_serializable_state() -> SerializableWorldState:
	var state := SerializableWorldState.new()
	if world_state:
		state = world_state.to_network_serializable()
	return state


#region callbacks

func callback_player_created(player : Player) -> void:
	return


func callback_army_created(army : Army) -> void:
	var coord = army.coord
	var hex = world_state.grid.get_hex(coord)
	var new_position = to_position(coord)
	var army_form : ArmyForm = ArmyForm.create_form_of_army(hex, \
		coord, new_position)
	armies.add_child(army_form)

	#armies.add_child(ArmyForm.create_form_of_army(
		#world_state.grid.get_hex(coord),
		#coord,
		#to_position(coord)
	#))


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
	var _hex = world_state.grid.get_hex_at(coord)
	return


func callback_combat_started(armies : Array, coord : Vector2i) -> void:
	start_combat(armies, coord, null)


#endregion
