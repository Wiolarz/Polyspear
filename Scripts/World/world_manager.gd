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

var raging_battle : bool = false  # redirects grid_input to Battle Manager

var current_player : Player

""" grid
contains:
	Places - Resource node /+ Neutral camp
	Cities
	Terrain blocks
	Sentinels
"""
# stores all location objects with common parent class "Place" as coordinates
var grid : Array = [] #Array[Array[Place]]

# stores all heroes as coordinates
var hero_grid : Array = [] # Array[Array[Hero]]

var selected_hero : Hero

var combat_tile : Vector2i

#endregion


#region Main functions

func hide_world_map():
	for hero in get_children():
		hero.queue_free()
	for tile in W_GRID.get_children():
		tile.queue_free()


func next_player_turn():
	var player_idx = players.find(current_player)
	if player_idx + 1 == players.size():
		current_player = players[0]
	else:
		current_player = players[player_idx + 1]


func kill_hero(hero : Hero):
	hero_grid[hero.cord.x][hero.cord.y] = null
	hero.queue_free()

#endregion

#region Tools

func is_enemy_present(cord : Vector2i):
	if W_GRID.get_tile_controller(cord) == current_player:
		return false
	if W_GRID.get_army(cord) == null:
		return false 
	return true


#endregion

#region Player Actions

func grid_input(cord : Vector2i):
	"""
	What can happen:
	I Scenario - player doesn't have any hero selected:
		1 Selects empty/enemy spot -> return
		2 Selects ally hero -> set selected hero then return
		3 Select ally city -> show interface then return
	II Scenario - player has a hero selected
		1 Selects empty/enemy/ally city/ally hero spot -> move_hero()
		2 Selects the same hero -> unselect current hero



	Can:
		1 select new hero
		2 choose a legal tile to move a selected hero to
		3 choose a city
		4 if a hero is inside a city, a special interface will apear (either it simply selects the hero inside the city, then you can close the interaface and move freely)
		5 player selected trade interface between heroes
	"""

	if select_city(cord) or select_hero(cord) or selected_hero == null:
		return

	move_hero(cord)


func select_city(cord : Vector2i) -> bool:
	"""
	"""
	var city = W_GRID.get_city(cord)

	if city == null or city.controller != current_player:
		return false
	
	city.show_interface()
	return true


func select_hero(cord : Vector2i) -> bool:
	"""
	What can happen:
	I Scenario - player doesn't have any hero selected:
		1 Selects empty/enemy spot -> return false
		2 Selects ally hero -> set hero then return true
	II Scenario - player has a hero selected
		1 Selects the same hero  -> unselect current hero return true/false(no difference)
		2 Selects another ally hero -> return false

		
	
	"""
	# TODO test unselect/no unselect on double click and determine which is more intuitive for most playersc

	var new_hero = W_GRID.get_hero(cord)
	if new_hero == null:
		return false
	
	if new_hero == selected_hero:
		selected_hero = null
		return true

	if new_hero.controller == current_player:
		selected_hero = new_hero
		return true

	return false


func move_hero(cord : Vector2i):
	# moves the currently selected hero
	"""
	1 Check if the destination is a valid target (not a wall)
	2 Check if a tile is next to a hero
	3 Check if tile is occupied with ally hero (open trade menu return)
	4 if a tile is ally city enter and open city interface return
	5 if a tile is combat (start a battle, depending on the result either move the hero or remove him)
	6 move a hero to an open spot
	"""

	if not W_GRID.is_moveable(cord):
		return
	
	if not GridManager.is_adjacent(selected_hero.cord, cord):
		return

	var new_hero = W_GRID.get_hero(cord)
	if new_hero != null and new_hero.controller == current_player:
		selected_hero.trade(new_hero)
		return
	

	var city = W_GRID.get_city(cord)

	if city != null and city.controller == current_player:
		W_GRID.change_hero_position(selected_hero, cord)
		city.show_interface()
		return
	

	if is_enemy_present(cord):
		if combat(cord):
			print("you won")
			#clear the tile of enemy presence
			W_GRID.change_hero_position(selected_hero, cord)
			return
		
		else:
			print("hero died")
			return

	W_GRID.change_hero_position(selected_hero, cord)


func combat(cord : Vector2i):
	"""
	Starts a battle using Battle Manager (BM)
	"""
	print("combat")
	raging_battle = true

	combat_tile = cord
	
	hide_world_map()

	var armies : Array[Army] = [selected_hero.army, W_GRID.get_army(combat_tile)]
	var battle_map : BattleMap = W_GRID.grid[combat_tile.x][combat_tile.y].battle_map

	BM.start_battle(armies, battle_map)
	
func end_of_battle():
	if selected_hero.army.alive == false:
		selected_hero.army.destroy_army()
		selected_hero = null
	
	var defender_army : Army = W_GRID.get_army(combat_tile)
	if defender_army.alive == false:
		defender_army.destroy_army()
		move_hero(combat_tile)



	draw_world()


#endregion

#region World Setup

func draw_world():
	pass
	#W_GRID.generate_grid()
	#spawn_heroes()

func spawn_heroes():
	pass


func change_heroes_visibility():
	pass

func start_world(world_map : WorldMap) -> void:

	players = IM.get_active_players()

	assert(players.size() != 0, "ERROR WM.players is empty")
	
	current_player = players[0]


	raging_battle = false

	W_GRID.generate_grid(world_map)
	

func spawn_starting_heroes():
	pass

#endregion
