class_name BattleManagerFast extends BattleManagerFastCpp

## A helper class wrapping C++ battle manager 
## and adding useful integration/testing functions

var _integrity_check_move: MoveInfo

# Maps BMFast's integer IDs to DataUnit (for summons) or Unit (for already summoned)
var unit_mapping: Array = []

## Make a BattleManagerFast for MCTS purposes. 
## Parameter tgrid may be null, in which case TileGridFast is created automatically
static func from(bgstate: BattleGridState, tgrid: TileGridFast = null) -> BattleManagerFast:
	var new = BattleManagerFast.new()
	if tgrid == null:
		tgrid = TileGridFast.from(bgstate)
	
	new.set_tile_grid(tgrid)
	new.set_current_participant(bgstate.current_army_index)
	
	for army_idx in range(bgstate.armies_in_battle_state.size()):
		var army = bgstate.armies_in_battle_state[army_idx]
		new.set_army_team(army_idx,army_idx)
		
		for unit_idx in range(army.units.size()):
			var unit = army.units[unit_idx]
			if unit.dead:
				continue
			
			new.insert_unit(army_idx, unit_idx, unit.coord, unit.unit_rotation, false)
			for i in range(6):
				new.set_unit_symbol(army_idx, unit_idx, i, unit.template.symbols[i].type)
			if army_idx == bgstate.current_army_index:
				new.unit_mapping.push_back(unit)
	
		for unit_idx in range(army.units_to_summon.size()):
			var unit = army.units_to_summon[unit_idx]
			new.insert_unit(army_idx, unit_idx + army.units.size(), Vector2i.ZERO, 0, true)
			for i in range(6):
				new.set_unit_symbol(army_idx, unit_idx + army.units.size(), i, unit.symbols[i].type)
			if army_idx == bgstate.current_army_index:
				new.unit_mapping.push_back(unit)

	new.finish_initialization()
	
	if bgstate.state == BattleGridState.STATE_FIGHTING:
		new.force_battle_ongoing()

	return new

#region Libspear tuple <-> MoveInfo conversion

# Libspear tuple format - [unit_in_current_army_id, position]
func libspear_tuple_to_move_info(tuple: Array):
	var unit: int = tuple[0]
	var position: Vector2i = tuple[1]
	
	if unit_mapping[unit] is DataUnit: # Summon
		return MoveInfo.make_summon(unit_mapping[unit], position)
	else: # Move
		return MoveInfo.make_move(unit_mapping[unit].coord, position)

func move_info_to_libspear_tuple(move: MoveInfo):
	var unit: int
	match move.move_type:
		MoveInfo.TYPE_SUMMON:
			unit = unit_mapping.find(move.summon_unit)
		MoveInfo.TYPE_MOVE:
			unit = get_unit_id_on_position(move.move_source)[1]
		_:
			assert(false, "Unknown move type '%s'" % [move.move_type])
	
	var pos = move.target_tile_coord
	return [unit, pos]

#endregion

#region Integrity testing

func check_integrity_before_move(bgs: BattleGridState, move: MoveInfo):
	if CFG.debug_check_bmfast_integrity:
		assert(compare_move_list(bgs), "BMFast Integrity check failed before move")
		assert(compare_grid_state(bgs), "BMFast Integrity check failed before move")
	
	if move.move_type == MoveInfo.TYPE_MOVE:
		var unit = bgs.get_unit(move.move_source)
		var unit_id = bgs.armies_in_battle_state[bgs.current_army_index].units.find(unit)
		assert(unit_id != -1, "BMFast Integrity check failed before move - unit on coords %s not found in fast" % move.move_source)
		
		play_move(unit_id, move.target_tile_coord)
		_integrity_check_move = move
	else:
		move = null


func check_integrity_after_move(bgs: BattleGridState):
	if CFG.debug_check_bmfast_integrity and bgs.state != bgs.STATE_BATTLE_FINISHED:
		#assert(compare_move_list(bgs), "BMFast Integrity check failed after move")
		
		if _integrity_check_move: # Only check ongoing battle moves
			assert(compare_grid_state(bgs), "BMFast Integrity check failed after move")
		

func compare_grid_state(bgs: BattleGridState) -> bool:
	var ret = true
	
	if bgs.current_army_index != get_current_participant():
		push_error("BMFast mismatch - current army: slow ", bgs.current_army_index, " fast", get_current_participant())
		ret = false
	
	for army_id in range(bgs.armies_in_battle_state.size()):
		var units_nr = 5
		var army = bgs.armies_in_battle_state[army_id]
		
		assert(army.units.size() + army.units_to_summon.size() <= 5, "No support for more than 5 units in fast BM")
		for unit_id in range(5):
			if not is_unit_alive(army_id, unit_id):
				units_nr -= 1
				continue # probably no need to check summons/dead
			
			var unit: Unit = bgs.get_unit(get_unit_position(army_id, unit_id))
			if unit == null:
				push_error("BMFast mismatch - unit not present in slow - fast id:", army_id, ".", unit_id, "(@", get_unit_position(army_id, unit_id), ")")
				ret = false
				continue
			if unit.unit_rotation != get_unit_rotation(army_id, unit_id):
				push_error("BMFast mismsatch - unit: id ", army_id, ".", unit_id, " slow has rotation ", unit.unit_rotation, \
						   ",  ", " vs fast's rotation ", get_unit_rotation(army_id, unit_id), " (@", unit.coord, ")")
				ret = false
				
		var units_alive_in_army = army.units.filter(func(x): return not x.dead).size()
		if units_nr != units_alive_in_army:
			push_error("BMFast mismatch - number of units in army ", army_id, ": slow ", units_alive_in_army, ", fast ", units_nr)
			ret = false
	
	return ret

func compare_move_list(bgs: BattleGridState) -> bool:
	var ret = true
	
	var fast_moves = get_legal_moves()
	var slow_moves = bgs.get_possible_moves()
	
	for i in fast_moves:
		var move = libspear_tuple_to_move_info(i)
		if not bgs.is_move_possible(move):
			push_error("BMFast move mismatch - fast move %s (%s) not present in slow" % [i, move])
			ret = false
	
	for i in slow_moves:
		if move_info_to_libspear_tuple(i) not in fast_moves:
			push_error("BMFast move mismatch - slow %s not present in fast" % [i])
			ret = false

	return ret
	
#endregion
