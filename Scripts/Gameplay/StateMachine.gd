class_name StateMachine


extends Node


var Controller : E.Player



var states : Dictionary = {} # there should always be at least a single state

var current_state



#region TOOLS

func GetAllLegalMoves(myUnits : Array): # -> Array[Array[Vector2i]]
	"""
	Compares every possible directions for all units using:
	1 Check for friendly units placements
	2 Sentinel Tiles
	3 GameplayManager -> LegalMove()
	"""
	Controller = myUnits[0].Controller
	var legalMoves = []

	for myUnit in myUnits:
		
		for side in range(6):
			var new_move = myUnit.CurrentCord + GRID.Directions[side]
			var neighbour : AUnit = GRID.GetUnit(new_move)
			if (neighbour != null and neighbour.Controller == Controller): # 1
				continue
			
			if GRID.GetTileType(new_move) == E.HexTileType.SENTINEL: # 2
				continue
			
			if GM.IsLegalMove(new_move, myUnit) == -1:
				continue
			
			legalMoves.append([myUnit.CurrentCord, new_move])
	return legalMoves


func GetAllKillMoves(AllMoves):  # Array[Array[Vector2i]]
	"""
	TODO:
	BOW is not working properly
	"""
	var AllKillMoves = []
	for Move in AllMoves:
		
		# BOW
		if GRID.GetUnit(Move[0]).GetSymbol(0) == E.Symbols.BOW:
			if GRID.GetShotTarget(Move[0], GRID.AdjacentSide(Move[0], Move[1])):
				AllKillMoves.append(Move)
			continue
		
		if GRID.GetUnit(Move[1]) != null:
			AllKillMoves.append(Move)
	
	return AllKillMoves




func GetAllSpawnMoves(my_units : Array):
	"""
	Compares every possible directions for all units using:
	1 Check for friendly units placements
	2 Sentinel Tiles
	3 GameplayManager -> LegalMove()
	"""
	var legal_moves = []
	var spawn_tiles = []

	if my_units[0].Controller == E.Player.ATTACKER:
		spawn_tiles = GRID.AttackerTiles
	else:
		spawn_tiles = GRID.DefenderTiles

	for unit in my_units:
		if GRID.GetTileType(unit.CurrentCord) != E.HexTileType.SENTINEL:
			continue
		for tile in spawn_tiles:
			if GRID.GetUnit(tile.TileIndex) == null:
				legal_moves.append([unit.CurrentCord, tile.TileIndex])
	
	return legal_moves

#endregion








func _ready():
	
	#region Get States
	"""
	
	"""
	var children = get_children()

	for child in children:
		
		if child.StartingState:
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
	
	pass








func PlayMove(myUnits : Array):
	if GM.UnitsLeftToBeSummoned != 0:
		var opening_moves = GetAllSpawnMoves(myUnits)
		return current_state.make_move(opening_moves)
	
	var legal_moves = GetAllLegalMoves(myUnits)
	var kill_moves = GetAllKillMoves(legal_moves)
	if kill_moves.size() > 0:
		return kill_moves[randi_range(0, kill_moves.size() - 1)]

	return current_state.make_move(legal_moves)
	
	
