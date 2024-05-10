# Singleton - WM
extends Node


#region Setup Parameters
"""
Current simplifications:
1 All players are host-seat
2 Basic same map
3 Same game parameters set as const

"""

var players : Array[Player] = []

#endregion


#region Variables
var world_ui : WorldUI = null
var current_player : Player

## Only army that has a hero can move (army can only have a single hero)
var selected_hero : ArmyForm
var combat_tile : Vector2i

#endregion


#region helpers

func get_bounds_global_position() -> Rect2:
	return W_GRID.get_bounds_global_position()

func set_selected_hero(new_hero : ArmyForm):
	print("selected ", new_hero)
	if selected_hero:
		selected_hero.set_selected(false)
	selected_hero = new_hero
	if selected_hero:
		selected_hero.set_selected(true)


func spawn_neutral_army(army_preset : PresetArmy, coord : Vector2i) -> ArmyForm:
	var player_army_presence = W_GRID.get_army(coord)
	if player_army_presence != null:
		printerr("neutral army attacking player has not been implemented") # TODO FIX

	print("neutral army spawn on: ", str(coord))
	var army_for_world_map : ArmyForm = \
		ArmyForm.create_neutral_army(army_preset)

	add_child(army_for_world_map)

	W_GRID.place_army(army_for_world_map, coord)
	return army_for_world_map

#endregion # helpers


#region Main functions

func next_player_turn():
	set_selected_hero(null)
	world_ui.show_trade_ui(current_player.capital_city, null)

	_end_of_turn_callbacks(current_player)
	var player_idx = players.find(current_player)
	if player_idx + 1 == players.size():
		_end_of_day_callbacks()
		current_player = players[0]
	else:
		current_player = players[player_idx + 1]
	world_ui.show_trade_ui(current_player.capital_city, null)



func _end_of_turn_callbacks(player : Player):
	W_GRID.end_of_turn_callbacks(player)


func _end_of_day_callbacks() -> void:
	for column in W_GRID.places:
		for place : Place in column:
			if place == null:
				continue
			place.on_end_of_turn()

#endregion


#region Player Actions

## Called when player interacts (presses) on the map tile
## Selects objects OR orders selected object
## City/Heroes -> orders Heroes
func grid_input(coord : Vector2i):
	print("world input @", coord)

	if selected_hero == null:
		input_try_select(coord)
		return

	#TEMP in future there will be pathfiding here
	if not GridManager.is_adjacent(selected_hero.coord, coord):
		set_selected_hero(null)
		return

	try_interact(selected_hero, coord)

## Tries to Select owned Hero
func input_try_select(coord) -> void:  #TODO "nothing is selected try to select stuff"
	var selected_spot_type : String = W_GRID.get_interactable_type(coord)
	if selected_spot_type == "army":
		var army_form : ArmyForm = W_GRID.get_army(coord)
		if current_player == army_form.entity.controller:
			set_selected_hero(army_form)


func try_interact(hero : ArmyForm, coord : Vector2i):

	if W_GRID.is_enemy_present(coord, current_player):
		if not hero.has_movement_points():
			print("not enough movement points")
			return
		start_combat(hero, coord)

	var selected_spot_type : String = W_GRID.get_interactable_type(coord)

	if selected_spot_type == "army":
		var army = W_GRID.get_army(coord)
		if current_player == army.controller:
			# ARMY TRADE
			trade_armies(army)
		return

	if selected_spot_type == "city":
		var city = W_GRID.get_city(coord)
		if city.controller == current_player:
			# CITY TRADE
			trade_city(city, hero)
		else:
			# CITY SIEGE
			print ("siege not implemented")
		return

	if W_GRID.is_moveable(coord):
		if not hero.has_movement_points():
			print("not enough movement points")
			return
		print("moving ", hero," to ",coord)
		hero_move(hero, coord)
		hero.spend_movement_point()


func hero_move(hero : ArmyForm, coord : Vector2i):
	W_GRID.change_hero_position(hero, coord)
	world_ui.show_trade_ui(current_player.capital_city, null)
	var place = W_GRID.places[coord.x][coord.y]
	if place != null:
		place.interact(hero)

func trade_armies(_second_army : ArmyForm):
	#TODO
	print("trading armies")

#endregion


#region City Management


func trade_city(city : City, hero : ArmyForm):
	print("trade_city")
	hero.entity.heal_in_city()
	world_ui.show_trade_ui(city, hero)


func recruit_hero(player : Player, hero_data : DataHero, coord : Vector2i) -> void:
	var army_for_world_map : ArmyForm = \
		ArmyForm.create_hero_army(player, hero_data)

	add_child(army_for_world_map)
	player.hero_recruited(army_for_world_map)

	# FIXME drut, adding hero unit to the army
	var hero_unit = army_for_world_map.entity.hero.data_unit
	army_for_world_map.entity.units_data.append(hero_unit)

	W_GRID.place_army(army_for_world_map, coord)

#endregion


#region Battles

func start_combat(attacking_army : ArmyForm, coord : Vector2i):
	"""
	Starts a battle using Battle Manager (BM)
	"""
	print("start_combat")

	combat_tile = coord
	var armies : Array[Army] = [
		attacking_army.entity,
		W_GRID.get_army(combat_tile).entity,
	]
	var battle_map : DataBattleMap = W_GRID.get_battle_map(combat_tile)
	var x_offset = get_bounds_global_position().end.x + CFG.MAPS_OFFSET_X

	BM.start_battle(armies, battle_map, x_offset)
	IM.switch_camera()


func end_of_battle(battle_results : Array[BM.ArmyInBattleState]):
	#TODO get result from Battle Manager
	if battle_results[BM.ATTACKER].can_fight():
		print("attacker won")
		kill_army(W_GRID.get_army(combat_tile)) # clear the tile of enemy presence
		hero_move(selected_hero, combat_tile)
		selected_hero.apply_losses(battle_results[BM.ATTACKER].dead_units)
	else:
		kill_army(selected_hero)  # clear the tile where selected_hero was
		set_selected_hero(null)
		print("hero died")
		var defender_army = W_GRID.get_army(combat_tile)
		defender_army.apply_losses(battle_results[BM.DEFENDER].dead_units)
	UI.go_to_custom_ui(world_ui)


func kill_army(army : ArmyForm):
	if army.entity.hero:
		army.controller.hero_died(army.entity.hero)
	W_GRID.unit_grid[army.coord.x][army.coord.y] = null  # there can only be one army at a single tile
	army.queue_free()
	world_ui.city_ui._refresh_all()

# endregion


#region World End

func close_world():
	selected_hero = null
	for hero in get_children():
		hero.queue_free()

	W_GRID.reset_data()

#endregion


#region World Setup

func spawn_world_ui():
	world_ui = load("res://Scenes/UI/WorldUi.tscn").instantiate()
	UI.add_custom_screen(world_ui)


func start_world(world_map : DataWorldMap) -> void:
	BM.battle_is_ongoing = false

	var spawn_location = world_map.get_spawn_locations()

	for coord in spawn_location:
		print("spawn: ",  W_GRID.to_bordered_coords(coord))

	players = IM.get_active_players()

	assert(players.size() != 0, "ERROR WM.players is empty")

	current_player = players[0]
	if world_ui == null or not is_instance_valid(world_ui):
		spawn_world_ui()
	UI.go_to_custom_ui(world_ui)
	world_ui.refresh_player_buttons()

	W_GRID.generate_grid(world_map)

	for player_id in range(players.size()):
		spawn_player(spawn_location[player_id], players[player_id])

	world_ui.show_trade_ui(current_player.capital_city, null)


func spawn_player(coord : Vector2i, player : Player):

	var fixed_coord =  W_GRID.to_bordered_coords(coord)
	# recruit_hero(player, player.faction.heroes[0], fixed_coord)

	var capital_city = W_GRID.get_city(fixed_coord)
	player.set_capital(capital_city)

#endregion
