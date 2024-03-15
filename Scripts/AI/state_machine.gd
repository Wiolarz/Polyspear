class_name StateMachine

extends AIInteface


var controller : Player


var states : Dictionary = {} # there should always be at least a single state

var current_state



#region TOOLS

func get_all_legal_moves(my_units : Array): # -> Array[Array[Vector2i]]
	"""
	Compares every possible directions for all units using:
	1 Check for friendly units placements
	2 Sentinel Tiles
	3 GameplayManager -> LegalMove()
	"""
	controller = my_units[0].controller
	var legal_moves = []

	for my_unit in my_units:
		
		for side in range(6):
			var new_move = my_unit.cord + B_GRID.DIRECTIONS[side]
			var neighbour : AUnit = B_GRID.get_unit(new_move)
			if (neighbour != null and neighbour.controller == controller): # 1
				continue
			
			if B_GRID.get_tile_type(new_move) == E.HexTileType.SENTINEL: # 2
				continue
			
			if BM.is_legal_move(new_move, my_unit) == -1:
				continue
			
			legal_moves.append([my_unit.cord, new_move])
	return legal_moves


func get_all_kill_moves(all_moves):  # Array[Array[Vector2i]]
	"""
	TODO:
	BOW is not working properly
	"""
	var all_kill_moves = []
	for move in all_moves:
		
		# BOW
		if B_GRID.get_unit(move[0]).get_symbol(0) == E.Symbols.BOW:
			if B_GRID.GetShotTarget(move[0], GridManager.adjacent_side(move[0], move[1])):
				all_kill_moves.append(move)
			continue
		
		if B_GRID.get_unit(move[1]) != null:
			all_kill_moves.append(move)
	
	return all_kill_moves




func get_all_spawn_moves(my_units : Array):
	"""
	Compares every possible directions for all units using:
	1 Check for friendly units placements
	2 Sentinel Tiles
	3 GameplayManager -> LegalMove()
	"""
	var legal_moves = []
	var spawn_tiles = []

	if my_units[0].controller == BM.commanders[0].controller:
		spawn_tiles = B_GRID.AttackerTiles
	else:
		spawn_tiles = B_GRID.DefenderTiles

	for unit in my_units:
		if B_GRID.get_tile_type(unit.cord) != E.HexTileType.SENTINEL:
			continue
		for tile in spawn_tiles:
			if B_GRID.get_unit(tile.cord) == null:
				legal_moves.append([unit.cord, tile.cord])
	
	return legal_moves

#endregion








func _ready():
	
	#region Get States
	"""
	
	"""
	var children = get_children()

	for child in children:
		
		if child.starting_state:
			current_state = child


		for tag in child.tags:
			if tag in states.keys():
				states[tag].append(child)
			else:
				states[tag] = [child]
	#endregion



func change_state(new_states):
	var new_chosen_state
	for new_state in new_states:

		if new_state in states.keys():
			new_chosen_state = new_state
			break
		
	if new_chosen_state == null:
		for state in states.keys():
			if state not in current_state.tags:
				new_chosen_state = state
				break
		new_chosen_state = states.keys()[0]
	
	# we have chosen the tag name for our new state, write the transisiton




func play_move(player : Player):
	var my_units : Array[AUnit]
	for units in BM.fighting_units:
		if units[0].controller == player:
			my_units = units
			break

	
	if BM.UnitsLeftToBeSummoned != 0:
		var opening_moves = get_all_spawn_moves(my_units)
		return current_state.make_move(opening_moves)
	
	var legal_moves = get_all_legal_moves(my_units)
	var kill_moves = get_all_kill_moves(legal_moves)
	if kill_moves.size() > 0:
		return kill_moves[randi_range(0, kill_moves.size() - 1)]

	return current_state.make_move(legal_moves)
