class_name BattleGridState
extends GenericHexGrid

signal on_turn_started(player : Player)
signal on_unit_summoned(unit : Unit)
signal on_battle_ended()

const STATE_SUMMONNING = "summonning"
const STATE_FIGHTING = "fighting"
const STATE_BATTLE_FINISHED = "battle_finished"

const MOVE_IS_INVALID = -1

const STALEMATE_TURN_COUNT = 150

var state : String = ""
var turn_counter : int = 0
var current_army_index : int = 0
var armies_in_battle_state : Array[ArmyInBattleState] = []


#region init

func _init(width_ : int, height_ : int):
	super(width_, height_, BattleHex.sentinel)


static func create(map: DataBattleMap, new_armies : Array[Army]) -> BattleGridState:
	var result = BattleGridState.new(map.grid_width, map.grid_height)
	result.state = STATE_SUMMONNING
	for a in new_armies:
		result.armies_in_battle_state.append(ArmyInBattleState.create_from(a, result))
	result.current_army_index = 0
	result.turn_counter = 0

	for x in range(map.grid_width):
		for y in range(map.grid_height):
			var map_tile : DataTile = map.grid_data[x][y]
			result.set_hex(Vector2i(x,y), BattleHex.create(map_tile))
	return result

#endregion

#region move_info support

func move_info_summon_unit(unit_data : DataUnit, coord : Vector2i) -> void:
	var initial_rotation = get_spawn_rotation(coord)
	var army_state = armies_in_battle_state[current_army_index]
	var unit = army_state.summon_unit(unit_data, coord, initial_rotation)
	put_unit_on_grid(unit, coord)
	switch_participant_turn()


func move_info_move_unit(source_tile_coord: Vector2i, target_tile_coord : Vector2i) -> void:
	var unit = get_unit(source_tile_coord)
	var direction = GenericHexGrid.direction_to_adjacent(unit.coord, target_tile_coord)

	perform_move(unit, direction, target_tile_coord)

	turn_counter += 1
	check_battle_end()
	switch_participant_turn()


func perform_move(unit : Unit, direction : int, target_tile_coord : Vector2i) -> void:
	# TURN
	unit.turn(direction)
	if process_symbols(unit):
		return
	# MOVE
	change_unit_coord(unit, target_tile_coord)
	unit.move(target_tile_coord)
	if process_symbols(unit):
		return

#end region

#region Symbols

## returns true when unit should stop processing further steps
## it died or battle ended
func process_symbols(unit : Unit) -> bool:
	if should_die_to_counter_attack(unit):
		kill_unit(unit)
		return true
	process_offensive_symbols(unit)
	if not battle_is_ongoing():
		return true
	return false


func should_die_to_counter_attack(unit : Unit) -> bool:
	# Returns true if Enemy counter_attack can kill the target
	var adjacent = adjacent_units(unit.coord)

	for side in range(6):
		if not adjacent[side]:
			continue # no unit
		if adjacent[side].controller == unit.controller:
			continue # no friendly fire
		if unit.get_symbol(side) == E.Symbols.SHIELD:
			continue # we have a shield
		if adjacent[side].get_symbol(side + 3) == E.Symbols.SPEAR:
			return true # enemy has a counter_attack
	return false


func process_bow(unit : Unit, side : int) -> void:
	var target = get_shot_target(unit.coord, side)

	if target == null:
		return # no target
	if target.controller == unit.controller:
		return # no friendly fire
	if target.get_symbol(side + 3) == E.Symbols.SHIELD:
		return  # blocked by shield

	kill_unit(target)


func process_offensive_symbols(unit : Unit) -> void:
	var adjacent = adjacent_units(unit.coord)

	for side in range(6):
		var unit_weapon = unit.get_symbol(side)
		if unit_weapon in [E.Symbols.EMPTY, E.Symbols.SHIELD]:
			continue # We don't have any weapon
		if unit_weapon == E.Symbols.BOW:
			process_bow(unit, side)
			continue # bow is special case
		if not adjacent[side]:
			continue # nothing to interact with
		if adjacent[side].controller == unit.controller:
			continue # no friendly fire

		var enemy = adjacent[side]
		if unit_weapon == E.Symbols.PUSH:
			push_enemy(enemy, side)
			continue # push is special case
		if enemy.get_symbol(side + 3) == E.Symbols.SHIELD:
			continue # enemy defended
		kill_unit(enemy)


func push_enemy(enemy : Unit, direction : int) -> void:
	var target_coord = GenericHexGrid.distant_coord(enemy.coord, direction, 1)

	if not is_movable(target_coord):
		# Pushing outside the map
		kill_unit(enemy)
		return

	var target = get_unit(target_coord)
	if target != null:
		# Spot isn't empty
		kill_unit(enemy)
		return

	# MOVE for PUSH (no rotate)
	change_unit_coord(enemy, target_coord)
	enemy.move(target_coord)

	# check for counter_attacks
	if should_die_to_counter_attack(enemy):
		kill_unit(enemy)

#endregion

func get_current_player() -> Player:
	return armies_in_battle_state[current_army_index].army_reference.controller


func switch_participant_turn() -> void:
	current_army_index += 1
	current_army_index %= armies_in_battle_state.size()
	print(NET.get_role_name(), " switch_participant_turn ", current_army_index)

	if state == STATE_SUMMONNING:
		var skip_count = 0
		# skip players with nothing to summon
		while armies_in_battle_state[current_army_index].units_to_summon.size() == 0:
			current_army_index += 1
			current_army_index %= armies_in_battle_state.size()
			skip_count += 1
			# no player has anything to summon, go to next phase
			if skip_count == armies_in_battle_state.size():
				end_summoning_state()
				break
		on_turn_started.emit(get_current_player())

	elif state == STATE_FIGHTING:
		while not armies_in_battle_state[current_army_index].can_fight():
			current_army_index += 1
			current_army_index %= armies_in_battle_state.size()

		on_turn_started.emit(get_current_player())

func get_battle_hex(coord : Vector2i) -> BattleHex:
	return get_hex(coord)


func can_summon_on(army_idx : int, coord : Vector2i) -> bool:
	var hex := get_battle_hex(coord)
	return  hex.spawn_point_army_idx == army_idx and hex.unit == null


func get_summon_coords(army_idx : int) -> Array[Vector2i]:
	var result : Array[Vector2i] = []
	for x in range(width):
		for y in range(height):
			var coord := Vector2i(x,y)
			if can_summon_on(army_idx, coord):
				result.append(coord)
	return result


func get_spawn_rotation(coord : Vector2i) -> int:
	return get_battle_hex(coord).spawn_direction


func spawn_unit_at_coord(unit : Unit, coord : Vector2i) -> void:
	put_unit_on_grid(unit, coord)


func put_unit_on_grid(unit : Unit, coord : Vector2i) -> void:
	var hex := get_battle_hex(coord)
	assert(hex.can_be_moved_to, "summoning unit to an invalid tile")
	assert(not hex.unit, "summoning unit to an occupied tile")
	hex.unit = unit


func get_unit(coord : Vector2i) -> Unit:
	return get_battle_hex(coord).unit


func change_unit_coord(unit : Unit, target_coord : Vector2i) -> void:
	remove_unit(unit)
	put_unit_on_grid(unit, target_coord)


func remove_unit(unit : Unit) -> void:
	var hex := get_battle_hex(unit.coord)
	assert(hex.unit == unit, "incorrect remove unit, coord desync")
	hex.unit = null


func is_movable(coord : Vector2i) -> bool:
	return get_battle_hex(coord).can_be_moved_to


func adjacent_units(coord : Vector2i) -> Array[Unit]:
	var result : Array[Unit] = []
	for dir in range(6):
		var target_coord := GenericHexGrid.adjacent_coord(coord, dir)
		result.append(get_unit(target_coord))
	return result


func get_shot_target(coord : Vector2i, direction : int) -> Unit:
	var target_coord := GenericHexGrid.adjacent_coord(coord, direction)
	var hex := get_battle_hex(target_coord)
	while not hex.unit and not hex.blocks_shots():
		target_coord = GenericHexGrid.adjacent_coord(target_coord, direction)
		hex = get_battle_hex(target_coord)
	return hex.unit


## Returns `MOVE_IS_INVALID` if move is incorrect
## or a turn direction `E.GridDirections` if move is correct
func get_move_direction_if_valid(unit : Unit, coord : Vector2i) -> int:
	"""
		For move to be valid, target coord
		- is a neighbor of the unit
		- allows movement
		- can be occupied by a new unit:
			- is empty
			- contains a unit that would be killed/pushed by the move

		@param unit to move
		@param coord target coord for unit to move to
		@return MOVE_IS_INVALID (-1) if move is illegal, direction otherwise
	"""

	var move_direction := GenericHexGrid.direction_to_adjacent(unit.coord, coord)
	# not adjacent
	if move_direction == TILES_NOT_ADJACENT:
		return MOVE_IS_INVALID

	var hex = get_battle_hex(coord)
	if not hex.can_be_moved_to:
		return MOVE_IS_INVALID

	var unit_on_target = hex.unit
	# empty field
	if not unit_on_target:
		return move_direction

	if not unit.can_kill_or_push(unit_on_target, move_direction):
		return MOVE_IS_INVALID

	return move_direction


func get_player_army(player : Player) -> BattleGridState.ArmyInBattleState:
	for army in armies_in_battle_state:
		if army.army_reference.controller == player:
			return army
	assert(false, "No army for player " + str(player))
	return null


func kill_unit(target : Unit) -> void:
	get_player_army(target.controller).kill_unit(target)
	check_battle_end()


#region End Battle

func kill_army(army_idx : int):
	armies_in_battle_state[army_idx].kill_army()
	check_battle_end()


## TEMP: After 50 turns Defender (army idx 1) wins
## in case 1 was eliminated last idx alive wins
func end_stalemate():
	for army_idx in range(armies_in_battle_state.size()):
		if army_idx == 1:
			continue
		kill_army(army_idx)
		if not battle_is_ongoing():
			break


func battle_is_ongoing() -> bool:
	return state != STATE_BATTLE_FINISHED


func check_battle_end() -> void:
	var armies_alive = 0
	for a in armies_in_battle_state:
		if a.can_fight():
			armies_alive += 1

	if armies_alive < 2:
		state = STATE_BATTLE_FINISHED
		on_battle_ended.emit()
		return

	# TEMP
	if turn_counter == STALEMATE_TURN_COUNT:
		turn_counter += 1  # XD
		end_stalemate()


func is_during_summoning_phase() -> bool:
	return state == STATE_SUMMONNING


func end_summoning_state() -> void:
	state = STATE_FIGHTING
	current_army_index = 0


func force_win_battle():
	for army_idx in range(armies_in_battle_state.size()):
		if army_idx == current_army_index:
			continue
		kill_army(army_idx)


func force_surrender():
	for army_idx in range(armies_in_battle_state.size()):
		if army_idx != current_army_index:
			continue
		kill_army(army_idx)


class BattleHex:
	var can_be_moved_to: bool
	var unit : Unit
	var spawn_point_army_idx : int
	var spawn_direction : int

	static var sentinel: BattleHex = BattleHex.new()

	func _init():
		can_be_moved_to = false
		spawn_point_army_idx = -1

	static func get_spawn_direction(army_id:int) -> int:
		match army_id:
			0: return GenericHexGrid.GridDirections.RIGHT
			2: return GenericHexGrid.GridDirections.TOP_RIGHT
			3: return GenericHexGrid.GridDirections.BOTTOM_LEFT
			_: return GenericHexGrid.GridDirections.LEFT


	static func create(data : DataTile):
		if data.type == "sentinel":
			return null
		var result = BattleHex.new()
		result.can_be_moved_to = true

		if data.type.substr(1) == "_player_spawn":
			result.spawn_point_army_idx = data.type[0].to_int() - 1
			result.spawn_direction = get_spawn_direction(result.spawn_point_army_idx)

		return result

	func blocks_shots() -> bool:
		return not can_be_moved_to


class ArmyInBattleState:
	var battle_grid_state : WeakRef # BattleGridState
	var army_reference : Army

	var units_to_summon : Array[DataUnit] = []
	var units : Array[Unit] = []
	var dead_units : Array[DataUnit] = []


	static func create_from(army : Army, state : BattleGridState) -> ArmyInBattleState:
		var result = ArmyInBattleState.new()
		result.battle_grid_state = weakref(state)
		result.army_reference = army
		for u in army.units_data:
			result.units_to_summon.append(u)
		return result


	func kill_unit(target : Unit) -> void:
		print("killing ", target.coord, " ",target.template.unit_name)
		units.erase(target)
		dead_units.append(target.template)
		battle_grid_state.get_ref().remove_unit(target)
		target.unit_killed()


	func kill_army() -> void:
		dead_units.append_array(units_to_summon)
		units_to_summon.clear()
		for unit_idx in range(units.size() - 1, -1, -1):
			kill_unit(units[unit_idx])


	func can_fight() -> bool:
		return units.size() > 0 or units_to_summon.size() > 0


	func summon_unit(unit_data : DataUnit, coord:Vector2i, rotation:int) -> Unit:
		units_to_summon.erase(unit_data)
		var result = Unit.create(army_reference.controller, unit_data, coord, rotation)
		units.append(result)
		battle_grid_state.get_ref().on_unit_summoned.emit(result)
		return result
