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

var selected_hero : ArmyOnWorldMap  # Only army that has a hero can move (army can only have a single hero)

var combat_tile : Vector2i

#endregion


#region helpers

func set_selected_hero(new_hero : ArmyOnWorldMap):
	print("selected ", new_hero)
	if selected_hero:
		selected_hero.set_selected(false)
	selected_hero = new_hero
	if selected_hero:
		selected_hero.set_selected(true)

#endregion # helpers


#region Main functions


func next_player_turn():
	set_selected_hero(null)
	var player_idx = players.find(current_player)
	if player_idx + 1 == players.size():
		_call_end_of_turn()
		current_player = players[0]
	else:
		current_player = players[player_idx + 1]

func _call_end_of_turn() -> void:
	for column in W_GRID.places:
		for place : Place in column:
			if place == null:
				continue
			place.on_end_of_turn()
#endregion


#region Player Actions

func grid_input(coord : Vector2i):
	"""
	I no hero selected
	if owned city/army:
		select()

	II hero selected
	if enemy_present:
		attack()
	elif city/army:
		trade()
	elif can_move_there:
		move()
	"""

	print("world input @", coord)

	var selected_spot_type : String = W_GRID.get_interactable_type(coord)

	if selected_hero == null:
		if selected_spot_type == "army":
			var army : ArmyOnWorldMap = W_GRID.get_army(coord)
			if current_player == army.army_data.controller:
				set_selected_hero(army)
		elif selected_spot_type == "city":
			pass
			#var city = W_GRID.get_city(coord)
			#if city.controller == current_player:
				##TODO CITY you could select current city here
				#city_show_interface(city)
		return

	else: # hero is selected
		#TEMP in future there will be pathfiding here
		if not GridManager.is_adjacent(selected_hero.coord, coord):
			set_selected_hero(null)
			return

		if W_GRID.is_enemy_present(coord, current_player):
			start_combat(coord)

		if selected_spot_type == "army":
			var army = W_GRID.get_army(coord)
			if current_player == army.controller:
				# ARMY TRADE
				trade_armies(army)

		elif selected_spot_type == "city":
			var city = W_GRID.get_city(coord)
			if city.controller == current_player:
				# CITY TRADE
				trade_city(city, selected_hero)
				pass
		else:
			if W_GRID.is_moveable(coord):
				print("moving ", selected_hero," to ",coord)
				hero_move(selected_hero, coord)


func hero_move(hero : ArmyOnWorldMap, coord : Vector2i):
	W_GRID.change_hero_position(hero, coord)
	var place = W_GRID.places[coord.x][coord.y]
	if place != null:
		place.interact(hero)

func trade_armies(_second_army : Army):
	#TODO
	pass


#endregion


#region City Management


func trade_city(_city : City, _hero:ArmyOnWorldMap ):
	print("trade_city")
	world_ui.show_trade_ui(_city, _hero)
	pass


func city_show_interface(_city : City):
	print("city shows interface")

"""


"""

#endregion


#region Battles

func start_combat(coord : Vector2i):
	"""
	Starts a battle using Battle Manager (BM)
	"""
	print("start_combat")
	IM.raging_battle = true

	combat_tile = coord

	IM.switch_camera()

	var armies : Array[Army] = [
		selected_hero.army_data,
		W_GRID.get_army(combat_tile).army_data,
	]
	var battle_map : BattleMap = W_GRID.get_battle_map(combat_tile)

	BM.start_battle(armies, battle_map)


func end_of_battle():
	#TODO get result from Battle Manager
	IM.raging_battle = false
	var result : bool = BM.get_battle_result()
	if result:
		print("you won")
		kill_army(W_GRID.get_army(combat_tile)) # clear the tile of enemy presence
		hero_move(selected_hero, combat_tile)
	else:
		set_selected_hero(null)
		print("hero died")
		kill_army(selected_hero)  # clear the tile where selected_hero was


func kill_army(army : ArmyOnWorldMap):
	W_GRID.unit_grid[army.coord.x][army.coord.y] = null  # there can only be one army at a single tile
	army.queue_free()

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

func start_world(world_map : WorldMap) -> void:

	var spawn_location = world_map.get_spawn_locations()

	for coord in spawn_location:
		print("spawn: ", coord + Vector2i(GridManager.border_size, GridManager.border_size))

	players = IM.get_active_players()

	assert(players.size() != 0, "ERROR WM.players is empty")

	current_player = players[0]
	if world_ui == null or not is_instance_valid(world_ui):
		spawn_world_ui()
	UI.go_to_custom_ui(world_ui)

	IM.raging_battle = false

	W_GRID.generate_grid(world_map)

	for player_id in range(players.size()):
		spawn_player(spawn_location[player_id], players[player_id])


func spawn_player(coords : Vector2i, player : Player):
	var army_for_world_map = load("res://Scenes/Form/ArmyForm.tscn").instantiate()
	add_child(army_for_world_map)
	army_for_world_map.name = "hero 1"
	army_for_world_map.army_data.controller = player

	var coord =  W_GRID.to_bordered_coords(coords)
	W_GRID.place_army(army_for_world_map, coord)
	W_GRID.get_city(coord).controller = player

#endregion
