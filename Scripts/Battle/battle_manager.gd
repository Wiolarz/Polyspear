# Singleton - BM
extends Node

#region variables

const ATTACKER = 0
const DEFENDER = 1

const STATE_SUMMONNING = "summonning"
const STATE_FIGHTING = "fighting"
const STATE_BATTLE_FINISHED = "battle_finished"

var battle_is_ongoing : bool = false
var state : String = ""
var armies_in_battle_state : Array[ArmyInBattleState] = []
var current_summary : DataBattleSummary = null
var current_army_index : int = ATTACKER
var turn_counter : int = 0

var battle_ui : BattleUI
var selected_unit : Unit

var _battle_grid: BattleGridState

var _replay : BattleReplay
var _replay_is_playing : bool = false

var _waiting_for_action_to_finish : bool

#endregion

func _ready():
	battle_ui = load("res://Scenes/UI/BattleUi.tscn").instantiate()
	UI.add_custom_screen(battle_ui)


#region Battle Setup

func start_battle(new_armies : Array[Army], battle_map : DataBattleMap, \
		x_offset : float) -> void:
	_replay = BattleReplay.create(new_armies, battle_map)
	_replay.save()
	UI.ensure_camera_is_spawned()
	UI.go_to_custom_ui(battle_ui)

	battle_is_ongoing = true
	_waiting_for_action_to_finish = false

	state = STATE_SUMMONNING
	current_summary = null
	armies_in_battle_state = []
	for a in new_armies:
		armies_in_battle_state.append(ArmyInBattleState.create_from(a))
	current_army_index = ATTACKER

	# GAMEPLAY GRID:
	_battle_grid = BattleGridState.create(battle_map)

	# GRAPHICS GRID:
	B_GRID.load_map(battle_map)
	B_GRID.position.x = x_offset

	selected_unit = null
	battle_ui.load_armies(armies_in_battle_state)

	turn_counter = 0

	notify_current_player_your_turn()

## Camera bounds
func get_bounds_global_position() -> Rect2:
	return B_GRID.get_bounds_global_position()

#endregion


#region Replay

func perform_replay(replay:BattleReplay) -> void:
	_replay_is_playing = true

	for m in replay.moves:
		if not battle_is_ongoing:
			return # terminating battle while watching
		await perform_replay_move(m)
		await replay_move_delay()
	_replay_is_playing = false


func replay_move_delay() -> void:
	await get_tree().create_timer(CFG.bot_speed_frames/60).timeout
	while IM.is_game_paused() or CFG.bot_speed_frames == CFG.BotSpeed.FREEZE:
		await get_tree().create_timer(0.1).timeout
		if not battle_is_ongoing:
			return # terminating battle while watching

#endregion


#region Input Functions

func get_current_player() -> Player:
	return armies_in_battle_state[current_army_index].army_reference.controller

## Currently only used for AI
func notify_current_player_your_turn() -> void:
	if not battle_is_ongoing:
		return
	battle_ui.start_player_turn(current_army_index)
	var army_controller = get_current_player()
	if army_controller:
		army_controller.your_turn()
	else:
		print("uncontrolled army's turn")


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
		notify_current_player_your_turn()

	elif state == STATE_FIGHTING:
		while not armies_in_battle_state[current_army_index].can_fight():
			current_army_index += 1
			current_army_index %= armies_in_battle_state.size()

		notify_current_player_your_turn()


## user clicked battle tile on given coordinates
func grid_input(coord : Vector2i) -> void:
	if _replay_is_playing:
		print("replay playing, input ignored")
		return

	if not battle_is_ongoing:
		print("battle finished, input ignored")
		return

	if _waiting_for_action_to_finish:
		print("anim playing, input ignored")
		return


	var current_player : Player = get_current_player()
	if current_player != null and current_player.bot_engine:
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
	var direction : int = _battle_grid.get_move_direction_if_valid(selected_unit, coord)
	if direction == BattleGridState.MOVE_IS_INVALID:
		return

	selected_unit.select_request.emit(false)
	var move_info = MoveInfo.make_move(selected_unit.coord, coord)
	selected_unit = null

	if NET.client:
		NET.client.queue_request_move(move_info)
		return # dont perform move, send it to server

	perform_move_info(move_info)

## Select friendly Unit on a given coord
## returns true if unit was selected
func try_select_unit(coord : Vector2i) -> bool:
	var new_unit : Unit = _battle_grid.get_unit(coord)
	if not new_unit:
		return false
	if new_unit.controller != get_current_player():
		return false

	# deselect visually old unit if selected
	if selected_unit:
		selected_unit.select_request.emit(false)

	selected_unit = new_unit
	new_unit.select_request.emit(true)
	return true


func perform_network_move(move_info : MoveInfo) -> void:
	await perform_move_info(move_info)


func perform_replay_move(move_info : MoveInfo) -> void:
	await perform_move_info(move_info)


func perform_ai_move(move_info : MoveInfo) -> void:
	await perform_move_info(move_info)


func perform_move_info(move_info : MoveInfo) -> void:
	if not battle_is_ongoing:
		return
	print(NET.get_role_name(), " performing move ", move_info)
	_replay.record_move(move_info)
	_replay.save()
	if NET.server:
		NET.server.broadcast_move(move_info)
	if move_info.move_type == MoveInfo.TYPE_MOVE:
		var unit = _battle_grid.get_unit(move_info.move_source)
		var dir = GenericHexGrid.direction_to_adjacent(unit.coord, move_info.target_tile_coord)
		assert(not _waiting_for_action_to_finish, \
				"cant trigger awaitable action while a different action is processing")
		_waiting_for_action_to_finish = true
		await move_info_move_unit(unit, move_info.target_tile_coord, dir)
		_waiting_for_action_to_finish = false
		switch_participant_turn()
		return
	if move_info.move_type == MoveInfo.TYPE_SUMMON:
		move_info_summon_unit(move_info.summon_unit, move_info.target_tile_coord)
		switch_participant_turn()
		return
	assert(false, "Move move_type not supported in perform")
#endregion


#region Symbols

## returns true when unit should stop processing further steps
## it died or battle ended
func process_symbols(unit : Unit) -> bool:
	if should_die_to_counter_attack(unit):
		await kill_unit(unit)
		return true
	await process_offensive_symbols(unit)
	if not battle_is_ongoing:
		return true
	return false


func should_die_to_counter_attack(unit : Unit) -> bool:
	# Returns true if Enemy counter_attack can kill the target
	var adjacent = _battle_grid.adjacent_units(unit.coord)

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
	var target = _battle_grid.get_shot_target(unit.coord, side)

	if target == null:
		return # no target
	if target.controller == unit.controller:
		return # no friendly fire
	if target.get_symbol(side + 3) == E.Symbols.SHIELD:
		return  # blocked by shield

	await kill_unit(target)


func process_offensive_symbols(unit : Unit) -> void:
	var adjacent = _battle_grid.adjacent_units(unit.coord)

	for side in range(6):
		var unit_weapon = unit.get_symbol(side)
		if unit_weapon in [E.Symbols.EMPTY, E.Symbols.SHIELD]:
			continue # We don't have any weapon
		if unit_weapon == E.Symbols.BOW:
			await process_bow(unit, side)
			continue # bow is special case
		if not adjacent[side]:
			continue # nothing to interact with
		if adjacent[side].controller == unit.controller:
			continue # no friendly fire

		var enemy = adjacent[side]
		if unit_weapon == E.Symbols.PUSH:
			await push_enemy(enemy, side)
			continue # push is special case
		if enemy.get_symbol(side + 3) == E.Symbols.SHIELD:
			continue # enemy defended
		await kill_unit(enemy)


func push_enemy(enemy : Unit, direction : int) -> void:
	var target_coord = GenericHexGrid.distant_coord(enemy.coord, direction, 1)

	if not _battle_grid.is_movable(target_coord):
		# Pushing outside the map
		await kill_unit(enemy)
		return

	var target = _battle_grid.get_unit(target_coord)
	if target != null:
		# Spot isn't empty
		await kill_unit(enemy)
		return

	# MOVE (no rotate)
	_battle_grid.change_unit_coord(enemy, target_coord)
	await enemy.move(target_coord)

	# check for counter_attacks
	if should_die_to_counter_attack(enemy):
		await kill_unit(enemy)

#endregion


#region Gameplay actions

func move_info_move_unit(unit : Unit, end_coord : Vector2i, direction: int) -> void:
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
	await unit.turn(direction)
	if await process_symbols(unit):
		return

	# MOVE

	_battle_grid.change_unit_coord(unit, end_coord)
	await unit.move(end_coord)
	if await process_symbols(unit):
		return

	turn_counter += 1
	await check_battle_end()


func get_player_army(player : Player) -> ArmyInBattleState:
	for army in armies_in_battle_state:
		if army.army_reference.controller == player:
			return army
	assert(false, "No army for player " + str(player))
	return null


func kill_unit(target : Unit) -> void:
	await get_player_army(target.controller).kill_unit(target, _battle_grid)
	await check_battle_end()

#endregion


#region End Battle

func kill_army(army_idx : int):
	assert(not _waiting_for_action_to_finish, \
			"cant trigger awaitable action while a different action is processing")
	_waiting_for_action_to_finish = true
	await armies_in_battle_state[army_idx].kill_army(_battle_grid)
	_waiting_for_action_to_finish = false
	await check_battle_end()

## TEMP: After 50 turns Defender wins
func end_stalemate():
	print("ending stalemate")
	# HACK, end_stalemate can happen during processing of a move
	# and it's fine
	_waiting_for_action_to_finish = false
	for army_idx in range(armies_in_battle_state.size()):
		if army_idx == DEFENDER:
			continue
		await kill_army(army_idx)


func check_battle_end() -> void:
	var armies_alive = 0
	for a in armies_in_battle_state:
		if a.can_fight():
			armies_alive += 1

	if armies_alive < 2:
		state = STATE_BATTLE_FINISHED
		end_the_battle()
		return

	# TEMP
	if turn_counter == 50:
		turn_counter += 1  # XD
		await end_stalemate()


func turn_off_battle_ui() -> void:
	battle_ui.hide()
	UI.switch_camera()


func reset_grid_and_unit_forms() -> void:
	battle_is_ongoing = false
	B_GRID.reset_data()
	_battle_grid = null
	for child in get_children():
		child.queue_free()


func end_the_battle() -> void:
	if not battle_is_ongoing:
		return
	battle_is_ongoing = false

	print("turns passed: ", turn_counter)

	await get_tree().create_timer(1).timeout # TEMP, don't exit immediately
	while _replay_is_playing:
		await get_tree().create_timer(0.1).timeout

	current_summary = create_summary()
	battle_ui.show_summary(current_summary, close_battle)


func close_battle() -> void:
	turn_off_battle_ui()
	reset_grid_and_unit_forms()

	if WM.selected_hero == null:
		print("end of test battle")
		IM.go_to_main_menu()
		return

	WM.end_of_battle(armies_in_battle_state)

#endregion


#region Summon Phase

func is_during_summoning_phase() -> bool:
	return state == STATE_SUMMONNING


func _grid_input_summon(coord : Vector2i) -> void:
	"""
	* Units are placed by the players in subsequent order on their chosen "Starting Locations"
	* inside the area of the gameplay board.
	"""
	if battle_ui.selected_unit == null:
		return # no unit selected

	if not is_legal_summon_coord(coord, current_army_index):
		return

	print(NET.get_role_name(), " input - summoning unit")
	var move_info = MoveInfo.make_summon(battle_ui.selected_unit, coord)
	if NET.client:
		NET.client.queue_request_move(move_info)
		return # dont perform move, send it to server
	perform_move_info(move_info)



func is_legal_summon_coord(coord : Vector2i, army_idx: int) -> bool:
	return _battle_grid.can_summon_on(army_idx, coord)


func move_info_summon_unit(unit_data : DataUnit, coord : Vector2i) -> void:
	"""
		Summon currently selected unit to a Gameplay Board

		@param coord coordinate, on which Unit will be summoned
	"""
	var rotation = GenericHexGrid.GridDirections.LEFT
	if current_army_index == ATTACKER:
		rotation = GenericHexGrid.GridDirections.RIGHT

	var army_state = armies_in_battle_state[current_army_index]
	var unit = army_state.summon_unit(self, unit_data, coord, rotation)
	_battle_grid.spawn_unit_at_coord(unit, coord)

	battle_ui.unit_summoned(not is_during_summoning_phase(), unit_data)


func end_summoning_state() -> void:
	state = STATE_FIGHTING
	current_army_index = ATTACKER

#endregion


#region AI Helpers

func get_summon_tiles(player : Player) -> Array[Vector2i]:
	var idx = find_army_idx(player)
	return _battle_grid.get_summon_coords(idx)


func get_not_summoned_units(player : Player) -> Array[DataUnit]:
	for a in armies_in_battle_state:
		if a.army_reference.controller == player:
			return a.units_to_summon.duplicate()
	assert(false, "ai asked for units to summon but it doesnt control any army")
	return []


func get_units(player : Player) -> Array[Unit]:
	var idx = find_army_idx(player)
	return armies_in_battle_state[idx].units


func find_army_idx(player : Player) -> int:
	for idx in range(armies_in_battle_state.size()):
		if armies_in_battle_state[idx].army_reference.controller == player:
			return idx
	assert(false, "ai asked for summon tiles but it doesnt control any army")
	return -1

#endregion


#region cheats

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

#endregion


#region Battle Summary


func get_summary() -> DataBattleSummary:
	if state != STATE_BATTLE_FINISHED:
		return null
	return current_summary


func create_summary() -> DataBattleSummary:
	var summary := DataBattleSummary.new()
	summary.color = CFG.NEUTRAL_COLOR.color
	summary.title = "Draw"

	for army_in_battle in armies_in_battle_state:
		var player_stats := DataBattleSummaryPlayer.new()
		if army_in_battle.dead_units.size() <= 0:
			player_stats.losses = "< none >"
		else:
			for dead in army_in_battle.dead_units:
				var unit_description = "%s\n" % dead.unit_name
				player_stats.losses += unit_description

		var army_controller := army_in_battle.army_reference.controller
		player_stats.player_description = IM.get_full_player_description(army_controller)
		if army_in_battle.can_fight():
			player_stats.state = "winner"
			var color_description = CFG.NEUTRAL_COLOR
			if army_controller:
				color_description = army_controller.get_player_color()
			summary.color = color_description.color
			summary.title = "%s wins" % color_description.name
		else:
			player_stats.state = "loser"
		summary.players.append(player_stats)
	return summary


#end region

class ArmyInBattleState:
	var army_reference : Army
	var units_to_summon : Array[DataUnit] = []
	var units : Array[Unit] = []
	var dead_units : Array[DataUnit] = []


	static func create_from(army : Army) -> ArmyInBattleState:
		var result = ArmyInBattleState.new()
		result.army_reference = army
		for u in army.units_data:
			result.units_to_summon.append(u)
		return result


	func kill_unit(target : Unit, grid : BattleGridState) -> void:
		print("killing ", target.coord, " ",target.template.unit_name)
		units.erase(target)
		dead_units.append(target.template)
		grid.remove_unit(target)
		await target.die()


	func kill_army(battle_grid : BattleGridState) -> void:
		dead_units.append_array(units_to_summon)
		units_to_summon.clear()
		for unit_idx in range(units.size() - 1, -1, -1):
			await kill_unit(units[unit_idx], battle_grid)


	func can_fight() -> bool:
		return units.size() > 0 or units_to_summon.size() > 0


	func summon_unit(battle_manager, unit_data : DataUnit, coord:Vector2i, rotation:int) -> Unit:
		units_to_summon.erase(unit_data)
		var result = Unit.create(army_reference.controller, unit_data, coord, rotation)
		var form := UnitForm.create(result)
		battle_manager.add_child(form)
		units.append(result)
		return result
