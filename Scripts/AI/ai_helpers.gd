class_name AIHelpers extends Object


static func get_all_legal_moves(me:Player, bm: BattleManager = BM) -> Array[MoveInfo]:
	"""
	Compares every possible directions for all units using:
	1 Check for friendly units placements
	2 Sentinel Tiles
	3 GameplayManager -> LegalMove()
	"""

	if bm.is_during_summoning_phase():
		return get_all_spawn_moves(me, bm)

	var legal_moves : Array[MoveInfo] = []

	for unit in bm.get_units(me):
		for side in range(6):
			var new_move = unit.coord + B_GRID.DIRECTIONS[side]
			var neighbour : Unit = B_GRID.get_unit(new_move)
			if (neighbour != null and neighbour.controller == me): # 1
				continue

			if bm.grid.get_tile_type(new_move) == "sentinel": # 2
				continue

			if bm.get_move_direction_if_valid(unit, new_move) == bm.MOVE_IS_INVALID:
				continue

			legal_moves.append(MoveInfo.make_move(unit.coord, new_move))
	return legal_moves


static func get_all_kill_moves(all_moves: Array[MoveInfo], me : Player, bm: BattleManager = BM) -> Array[MoveInfo]:
	var all_kill_moves : Array[MoveInfo] = []
	for move in all_moves:
		if is_kill_move(move, me, bm):
			all_kill_moves.append(move)

	return all_kill_moves


static func is_kill_move(move : MoveInfo, me : Player, bm: BattleManager = BM) -> bool:
	"""
	Only moves that kill something pass this filter.
	Note: Moving into enemy hex is a kill
	as only legal moves are allowed here
	"""
	if move.move_type != MoveInfo.TYPE_MOVE:
		return false

	var unit_on_target_field = bm.grid.get_unit(move.target_tile_coord)
	if unit_on_target_field != null \
			and unit_on_target_field.controller != me:
		return true

	# BOW
	var move_direction = GridManager.adjacent_side_direction( \
			move.move_source, move.target_tile_coord);
	for side in range(6):
		if bm.grid.get_unit(move.move_source).get_symbol(side) != E.Symbols.BOW:
			continue
		var shoot_direction = (move_direction + side) % 6
		var target : Unit = B_GRID.get_shot_target(move.move_source, shoot_direction)
		if  target != null and target.controller != me:
			return true
	return false


static func get_all_spawn_moves(me : Player, bm: BattleManager = BM) -> Array[MoveInfo]:
	"""
	Compares every possible directions for all units using:
	1 Check for friendly units placements
	2 Sentinel Tiles
	3 GameplayManager -> LegalMove()
	"""
	var legal_moves: Array[MoveInfo] = []

	var spawn_tiles = bm.get_summon_tiles(me)
	var units = bm.get_not_summoned_units(me)
	for unit in units:
		for spawn_tile in spawn_tiles:
			legal_moves.append(MoveInfo.make_summon(unit, spawn_tile.coord))

	return legal_moves
