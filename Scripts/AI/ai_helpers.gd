class_name AIHelpers extends Object


static func get_all_legal_moves(my_units : Array, _me:Player) -> Array[MoveInfo]:
	"""
	Compares every possible directions for all units using:
	1 Check for friendly units placements
	2 Sentinel Tiles
	3 GameplayManager -> LegalMove()
	"""
	var legal_moves : Array[MoveInfo] = []

	for unit in my_units:
		for side in range(6):
			var new_coord = GenericHexGrid.adjacent_coord(unit.coord, side)
			var move_dir = BM._battle_grid.get_move_direction_if_valid(unit, new_coord)
			if move_dir != BattleGridState.MOVE_IS_INVALID:
				legal_moves.append(MoveInfo.make_move(unit.coord, new_coord))
	return legal_moves


static func get_all_kill_moves(all_moves: Array[MoveInfo], me : Player) -> Array[MoveInfo]:
	var all_kill_moves : Array[MoveInfo] = []
	for move in all_moves:
		if is_kill_move(move, me):
			all_kill_moves.append(move)

	return all_kill_moves


static func is_kill_move(move : MoveInfo, me : Player) -> bool:
	"""
	Only moves that kill something pass this filter.
	Note: Moving into enemy hex is a kill
	as only legal moves are allowed here
	"""
	if move.move_type != MoveInfo.TYPE_MOVE:
		return false

	var unit_on_target_field = BM._battle_grid.get_unit(move.target_tile_coord)
	if unit_on_target_field != null \
			and unit_on_target_field.controller != me:
		return true

	# BOW
	var move_direction = GenericHexGrid.direction_to_adjacent( \
			move.move_source, move.target_tile_coord);
	for side in range(6):
		if BM._battle_grid.get_unit(move.move_source).get_symbol(side) != E.Symbols.BOW:
			continue
		var shoot_direction = GenericHexGrid.rotate_clockwise(move_direction, side)
		var target : Unit = BM._battle_grid.get_shot_target(move.move_source, shoot_direction)
		if  target != null and target.controller != me:
			return true
	return false


static func get_all_spawn_moves(me : Player) -> Array[MoveInfo]:
	"""
	Compares every possible directions for all units using:
	1 Check for friendly units placements
	2 Sentinel Tiles
	3 GameplayManager -> LegalMove()
	"""
	var legal_moves: Array[MoveInfo] = []

	var spawn_tiles = BM.get_summon_tiles(me)
	var units = BM.get_not_summoned_units(me)
	for unit in units:
		for spawn_tile in spawn_tiles:
			legal_moves.append(MoveInfo.make_summon(unit, spawn_tile))

	return legal_moves
