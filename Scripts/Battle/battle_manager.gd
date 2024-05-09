# Singleton - BM
extends Node

#region variables

const ATTACKER = 0
const DEFENDER = 1

const MOVE_IS_INVALID = -1

const STATE_SUMMONNING = "summonning"
const STATE_FIGHTING = "fighting"
const STATE_BATTLE_FINISHED = "battle_finished"

var battle_is_ongoing : bool = false
var state : String = ""
var army_in_battle_states : Array[ArmyInBattleState] = []
var current_army_index : int = ATTACKER

var battle_ui : BattleUI = null
var selected_unit : UnitForm = null

var _replay : BattleReplay
var _replay_is_playing : bool = false

#endregion

func _ready():
	battle_ui = load("res://Scenes/UI/BattleUi.tscn").instantiate()
	UI.add_custom_screen(battle_ui)


#region Main Functions

func start_battle(new_armies : Array[Army], battle_map : DataBattleMap, \
		x_offset : float) -> void:
	_replay = BattleReplay.create(new_armies, battle_map)
	_replay.save()
	UI.go_to_custom_ui(battle_ui)

	battle_is_ongoing = true
	state = STATE_SUMMONNING
	army_in_battle_states = []
	for a in new_armies:
		army_in_battle_states.append(ArmyInBattleState.create_from(a))
	current_army_index = ATTACKER

	B_GRID.generate_grid(battle_map)
	B_GRID.position.x = x_offset

	selected_unit = null
	battle_ui.load_armies(army_in_battle_states)

	notyfy_current_player_your_turn()


func get_current_player() -> Player:
	return army_in_battle_states[current_army_index].army_reference.controller


func notyfy_current_player_your_turn() -> void:
	if not battle_is_ongoing:
		return
	battle_ui.start_player_turn(current_army_index)
	var army_controller = get_current_player()
	if army_controller:
		army_controller.your_turn()
	else:
		print("uncontrolled army's turn")


func perform_replay(path : String):
	var replay = load(path) as BattleReplay
	assert(replay != null)
	_replay_is_playing = true
	var map = replay.battle_map
	var armies: Array[Army] = []
	var player_idx = 0
	while (IM.players.size() < replay.units_at_start.size()):
		IM.add_player("Replay_"+str(IM.players.size()))
	for p in IM.players:
		p.use_bot(false)
	for u in replay.units_at_start:
		var a = Army.new()
		a.units_data = u
		a.controller = IM.players[player_idx]
		armies.append(a)
		player_idx += 1
	start_battle(armies, map, 0)
	for m in replay.moves:
		if not battle_is_ongoing:
			return # terminating battle while watching
		perform_ai_move(m)
		await replay_move_delay()
	_replay_is_playing = false


func replay_move_delay():
	await get_tree().create_timer(CFG.bot_speed_frames/60).timeout
	while IM.is_game_paused() or CFG.bot_speed_frames == CFG.BotSpeed.FREEZE:
		await get_tree().create_timer(0.1).timeout
		if not battle_is_ongoing:
			return # terminating battle while watching


func switch_participant_turn():
	current_army_index += 1
	current_army_index %= army_in_battle_states.size()

	if state == STATE_SUMMONNING:
		var skip_count = 0
		# skip players with nothing to summon
		while army_in_battle_states[current_army_index].units_to_summon.size() == 0:
			current_army_index += 1
			current_army_index %= army_in_battle_states.size()
			skip_count += 1
			# no player has anything to summon, go to next phase
			if skip_count == army_in_battle_states.size():
				end_summoning_state()
				break
		notyfy_current_player_your_turn()

	elif state == STATE_FIGHTING:
		notyfy_current_player_your_turn()


func end_summoning_state() -> void:
	state = STATE_FIGHTING
	current_army_index = ATTACKER

## user clicked battle tile on given coordinates
func grid_input(coord : Vector2i) -> void:
	if _replay_is_playing:
		print("replay playing, input ignored")
		return

	if not battle_is_ongoing:
		print("battle finished, input ignored")
		return

	if get_current_player() and  get_current_player().bot_engine:
		print("ai playing, input ignored")
		return

	if is_during_summoning_phase(): # Summon phase
		_grid_input_summon(coord)
		return

	_grid_input_fighting(coord)


func _grid_input_fighting(coord : Vector2i) -> void:

	if try_select_unit(coord) or selected_unit == null:
		# selected a new unit
		# or no unit selected and tile with no ally clicked
		return

	# get_move_direction() returns MOVE_IS_INVALID on impossible moves
	# detects if spot is empty or there is an enemy that can be killed by the move
	var direction : int = get_move_direction_if_valid(selected_unit, coord)
	if direction == MOVE_IS_INVALID:
		return

	selected_unit.set_selected(false)
	perform_move_fighting(selected_unit, coord, direction)
	selected_unit = null
	switch_participant_turn()


func perform_move_fighting(unit : UnitForm, coord : Vector2i, direction : int):
	var move_info = MoveInfo.make_move(unit.coord, coord)
	if NET.client:
		NET.client.queue_request_move(move_info)
		return # dont perform move, send it to server
	_replay.record_move(move_info)
	_replay.save()
	if NET.server:
		NET.server.broadcast_move(move_info)
	move_unit(unit, coord, direction)


func perform_ai_move(move_info : MoveInfo):
	if not battle_is_ongoing:
		return
	_replay.record_move(move_info)
	_replay.save()
	if NET.server:
		NET.server.broadcast_move(move_info)
	if move_info.move_type == MoveInfo.TYPE_MOVE:
		var unit = B_GRID.get_unit(move_info.move_source)
		var dir = GridManager.adjacent_side_direction(unit.coord, move_info.target_tile_coord)
		move_unit(unit, move_info.target_tile_coord, dir)
		switch_participant_turn()
		return
	if move_info.move_type == MoveInfo.TYPE_SUMMON:
		summon_unit(move_info.summon_unit, move_info.target_tile_coord)
		switch_participant_turn()
		return
	assert(false, "Move move_type not supported in perform")


#endregion


#region Tools


func get_bounds_global_position() -> Rect2:
	return B_GRID.get_bounds_global_position()


## Select friendly UnitForm on a given coord
## returns true if unit was selected
func try_select_unit(coord : Vector2i) -> bool:
	var new_unit : UnitForm = B_GRID.get_unit(coord)
	if not new_unit:
		return false
	if new_unit.controller != get_current_player():
		return false

	# deselect visually old unit if selected
	if selected_unit:
		selected_unit.set_selected(false)

	selected_unit = new_unit
	new_unit.set_selected(true)
	return true


## Returns `MOVE_IS_INVALID` if move is incorrect
## or a turn direction `E.GridDirections` if move is correct
func get_move_direction_if_valid(unit : UnitForm, coord : Vector2i) -> int:
	"""
		Function checks 2 things:
		1 Target coord is a Neighbor of a selected_unit
		2a Target coord is empty
		2b Target coord contains unit that can be killed

		@param unit to move
		@param coord target coord for selected_unit to move to
		@return MOVE_IS_INVALID (-1) if move is illegal, direction otherwise
	"""

	var move_direction = GridManager.adjacent_side_direction(unit.coord, coord)
	# not adjacent
	if move_direction == null:
		return MOVE_IS_INVALID

	var enemy_unit = B_GRID.get_unit(coord)
	# empty field
	if not enemy_unit:
		return move_direction

	if not unit.can_kill(enemy_unit, move_direction):
		return MOVE_IS_INVALID

	return move_direction


func move_unit(unit : UnitForm, end_coord : Vector2i, direction: int) -> void:
	# Move General function
	"""
		Turns unit to @side then Moves unit to end_coord

		1 Turn
			2 Check for counter attack damage
			3 Actions
		4 Move to another tile
			5 Check for counter attack damage
			6 Actions

		@param end_coord Position at which unit will be placed
	"""

	# TURN
	unit.turn(direction)
	if process_symbols(unit):
		return

	# MOVE
	B_GRID.change_unit_coord(unit, end_coord)
	if process_symbols(unit):
		return


## returns true when unit should stop processing further steps
## it died or battle ended
func process_symbols(unit : UnitForm):
	if should_die_to_spear(unit):
		die_to_spear(unit)
		return true
	process_offensive_symbols(unit)
	if not battle_is_ongoing:
		return true
	return false


func die_to_spear(unit : UnitForm):
	kill_unit(unit)


func should_die_to_spear(unit : UnitForm) -> bool:
	# Returns true is Enemy spear can kill the target
	var adjacent = B_GRID.adjacent_units(unit.coord)

	for side in range(6):
		if not adjacent[side]:
			continue # no unit
		if adjacent[side].controller == unit.controller:
			continue # no friendly fire
		if unit.get_symbol(side) == E.Symbols.SHIELD:
			continue # we have a shield
		if adjacent[side].get_symbol(side + 3) == E.Symbols.SPEAR:
			return true # enemy has a spear
	return false


func get_army_for_player(player : Player):
	for a in army_in_battle_states:
		if a.army_reference.controller == player:
			return a
	assert(false, "No army for player " + str(player))


func kill_unit(target : UnitForm) -> void:
	get_army_for_player(target.controller).unit_died(target)
	B_GRID.remove_unit(target)

	check_battle_end()


func check_battle_end():
	var armies_alive = 0
	for a in army_in_battle_states:
		if a.can_fight():
			armies_alive += 1

	if armies_alive < 2:
		state = STATE_BATTLE_FINISHED
		end_the_battle()


func process_bow(unit : UnitForm, side:int):
	var target = B_GRID.get_shot_target(unit.coord, side)

	if target == null:
		return # no target
	if target.controller == unit.controller:
		return # no friendly fire
	if target.get_symbol(side + 3) == E.Symbols.SHIELD:
		return  # blocked by shield

	kill_unit(target)


func process_offensive_symbols(unit : UnitForm) -> void:
	var adjacent = B_GRID.adjacent_units(unit.coord)

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


func push_enemy(enemy : UnitForm, direction : int):
	var target_coord = B_GRID.get_distant_coord(enemy.coord, direction, 1)

	var target_tile_type = B_GRID.get_tile_type(target_coord)
	if target_tile_type == "sentinel":
		# Pushing outside the map
		kill_unit(enemy)
		return

	var target = B_GRID.get_unit(target_coord)
	if target != null:
		# Spot isn't empty
		kill_unit(enemy)
		return

	# MOVE (no rotate)
	B_GRID.change_unit_coord(enemy, target_coord)

	# check for spears
	if should_die_to_spear(enemy):
		kill_unit(enemy)


#endregion


#region End Battle


func close_battle() -> void:
	battle_is_ongoing = false
	while _replay_is_playing:
		await get_tree().create_timer(0.1).timeout

	battle_ui.hide()
	IM.switch_camera()

	# delete all data related to battle
	B_GRID.reset_data()
	for child in get_children():
		child.queue_free()


func end_the_battle() -> void:
	if not battle_is_ongoing:
		return

	battle_is_ongoing = false

	await get_tree().create_timer(1).timeout

	close_battle()

	if WM.selected_hero == null:
		print("end of test battle")
		IM.go_to_main_menu()
		return

	WM.end_of_battle(army_in_battle_states)

#endregion


#region Summon Phase

func is_during_summoning_phase() -> bool:
	return state == STATE_SUMMONNING


func _grid_input_summon(coord : Vector2i):
	"""
	* Units are placed by the players in subsequent order on their chosen "Starting Locations"
	* inside the area of the gameplay board.
	"""
	if battle_ui.selected_unit == null:
		return # no unit selected

	if not is_legal_summon_coord(coord, current_army_index):
		return

	var move_info = MoveInfo.make_summon(battle_ui.selected_unit, coord)
	if NET.client:
		NET.client.queue_request_move(move_info)
		return # dont perform move, send it to server
	_replay.record_move(move_info)
	_replay.save()
	if NET.server:
		NET.server.broadcast_move(move_info)
	summon_unit(battle_ui.selected_unit, coord)
	switch_participant_turn()


func is_legal_summon_coord(coord : Vector2i, army_idx: int) -> bool:
	var coord_tile_type = B_GRID.get_tile_type(coord)
	var is_correct_spawn =\
		(coord_tile_type == "red_spawn" && army_idx == 0) or \
		(coord_tile_type == "blue_spawn"&& army_idx == 1)
	return is_correct_spawn and B_GRID.get_unit(coord) == null


func summon_unit(unit_data : DataUnit, coord : Vector2i) -> void:
	"""
		Summon currently selected unit to a Gameplay Board

		@param coord coordinate, on which UnitForm will be summoned
	"""
	var unit = army_in_battle_states[current_army_index].summon_unit_form(unit_data)
	add_child(unit)
	B_GRID.change_unit_coord(unit, coord)

	if current_army_index == ATTACKER:
		unit.turn(3, true) # start turned right, default is left

	battle_ui.unit_summoned(not is_during_summoning_phase(), unit_data)

#endregion


#region AI Helpers

func get_summon_tiles(player : Player) -> Array[TileForm]:
	var idx = find_army_idx(player)
	var result: Array[TileForm] = []
	for c in B_GRID.get_all_field_coords():
		if is_legal_summon_coord(c, idx):
			result.append(B_GRID.get_tile(c))
	return result


func get_not_summoned_units(player : Player) -> Array[DataUnit]:
	for a in army_in_battle_states:
		if a.army_reference.controller == player:
			return a.units_to_summon.duplicate()
	assert(false, "ai asked for units to summon but it doesnt control any army")
	return []


func get_units(player : Player) -> Array[UnitForm]:
	var idx = find_army_idx(player)
	return army_in_battle_states[idx].units


func find_army_idx(player : Player):
	for idx in range(army_in_battle_states.size()):
		if army_in_battle_states[idx].army_reference.controller == player:
			return idx
	assert(false, "ai asked for summon tiles but it doesnt control any army")
	return -1

#endregion


#region Battle Setup


#endregion

#region cheats/decurrent_army_index
func force_win_battle():
	for idx in range(army_in_battle_states.size()):
		if idx == current_army_index:
			continue
		for unit in army_in_battle_states[idx].units:
			kill_unit(unit)


func force_surrender():
	for idx in range(army_in_battle_states.size()):
		if idx != current_army_index:
			continue
		for unit in army_in_battle_states[idx].units:
			kill_unit(unit)
#endregion

class ArmyInBattleState:
	var army_reference : Army
	var units_to_summon : Array[DataUnit] = []
	var units : Array[UnitForm] = []
	var dead_units : Array[DataUnit] = []


	static func create_from(army : Army) -> ArmyInBattleState:
		var result = ArmyInBattleState.new()
		result.army_reference = army
		for u in army.units_data:
			result.units_to_summon.append(u)
		return result


	func unit_died(target : UnitForm):
		units.erase(target)
		dead_units.append(target.unit_stats)


	func can_fight() -> bool:
		return units.size() > 0 or units_to_summon.size() > 0


	func summon_unit_form(unit_data : DataUnit) -> UnitForm:
		units_to_summon.erase(unit_data)
		var unit: UnitForm = CFG.UNIT_FORM_SCENE.instantiate()
		unit.apply_template(unit_data)
		unit.controller = army_reference.controller
		units.append(unit)
		return unit

