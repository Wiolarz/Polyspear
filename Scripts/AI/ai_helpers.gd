class_name AIHelpers extends Object


static func get_all_legal_moves(battle_state : BattleGridState) -> Array[MoveInfo]:
	"""
	Compares every possible directions for all units using:
	1 Check for friendly units placements
	2 Sentinel Tiles
	3 GameplayManager -> LegalMove()
	"""
	var legal_moves : Array[MoveInfo] = []
	var my_units := battle_state.get_units(battle_state.get_current_player())

	for unit in my_units:
		for side in range(6):
			var new_coord = GenericHexGrid.adjacent_coord(unit.coord, side)
			var move_dir = battle_state.get_move_direction_if_valid(unit, new_coord)
			if move_dir != BattleGridState.MOVE_IS_INVALID:
				legal_moves.append(MoveInfo.make_move(unit.coord, new_coord))
	return legal_moves


static func get_all_kill_moves(battle_state : BattleGridState, \
		all_moves: Array[MoveInfo]) -> Array[MoveInfo]:
	var all_kill_moves : Array[MoveInfo] = []
	for move in all_moves:
		if is_kill_move(battle_state, move):
			all_kill_moves.append(move)

	return all_kill_moves


static func is_kill_move(battle_state : BattleGridState, move : MoveInfo) -> bool:
	"""
	Only moves that kill something pass this filter.
	Note: Moving into enemy hex is a kill
	as only legal moves are allowed here
	"""
	if move.move_type != MoveInfo.TYPE_MOVE:
		return false

	var me = battle_state.get_current_player()

	var unit_on_target_field = battle_state.get_unit(move.target_tile_coord)
	if unit_on_target_field != null \
			and unit_on_target_field.controller != me:
		# can move into a unit and kill it
		# if it couldn't move would not be legal
		return true

	# BOW
	var attacker = battle_state.get_unit(move.move_source)
	var move_direction = GenericHexGrid.direction_to_adjacent( \
			move.move_source, move.target_tile_coord);
	for side in range(6):
		var opposite_side = GenericHexGrid.opposite_direction(side)
		var symbol = attacker.get_symbol_when_rotated(side, move_direction)
		if symbol == E.Symbols.BOW:
			var target : Unit = battle_state.get_shot_target(move.move_source, side)
			if target != null and target.controller != me \
					and target.get_symbol(opposite_side) != E.Symbols.SHIELD:
				# can shoot enemy in this direction
				return true

	# check for enemies near new field
	var target_adjacent_units = battle_state.adjacent_units(move.target_tile_coord)
	# check for enemy spears
	for side in 6:
		var enemy = target_adjacent_units[side]
		if enemy and enemy.controller != me:
			var opposite_side = GenericHexGrid.opposite_direction(side)
			if enemy.get_symbol(opposite_side) == E.Symbols.SPEAR:
				if attacker.get_symbol_when_rotated(move_direction, side) != E.Symbols.SHIELD:
					# will die to spear befor it can kill, no-go
					return false
	# check for unprotected attacker symbols
	for side in 6:
		var enemy = target_adjacent_units[side]
		if not enemy or enemy.controller == me:
			continue
		# TODO detect killing pushes
		var opposite_side = GenericHexGrid.opposite_direction(side)
		if enemy.get_symbol(opposite_side) == E.Symbols.SHIELD:
			continue
		var attack_symbol =  attacker.get_symbol_when_rotated(move_direction, side)
		if attack_symbol == E.Symbols.SWORD or attack_symbol == E.Symbols.SPEAR:
			return true
	return false


static func get_all_spawn_moves(battle_state : BattleGridState) -> Array[MoveInfo]:
	"""
	Compares every possible directions for all units using:
	1 Check for friendly units placements
	2 Sentinel Tiles
	3 GameplayManager -> LegalMove()
	"""
	var legal_moves: Array[MoveInfo] = []

	var me = battle_state.get_current_player()
	var spawn_tiles = battle_state.get_summon_tiles(me)
	var units = battle_state.get_not_summoned_units(me)
	for unit in units:
		for spawn_tile in spawn_tiles:
			legal_moves.append(MoveInfo.make_summon(unit, spawn_tile))

	return legal_moves
