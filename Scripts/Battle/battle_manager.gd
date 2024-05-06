# Singleton - BM
extends Node

#region variables

const ATTACKER = 0
const DEFENDER = 1

const MOVE_IS_INVALID = -1

const ONGOING = "ongoing"
const ATTACKER_WIN = "attacker_win"
const DEFENDER_WIN = "defender_win"
const NO_BATTLE = "no_battle"

var battle_is_ongoing : bool = false
var battle_result : String = ONGOING
## count units for transition between summon and battle steps
var unsummoned_units_counter : int

var battling_armies : Array[Army]

var participants : Array[Player] = []
var current_participant : Player
var participant_idx : int = ATTACKER

var selected_unit : UnitForm
var fighting_units : Array = [[],[]] # Array[Array[UnitForm]]

var battle_ui : BattleUI = null
var _replay : BattleReplay

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
	IM.raging_battle = true
	battle_is_ongoing = true
	battle_result = ONGOING
	unsummoned_units_counter = 0
	battling_armies = new_armies

	B_GRID.generate_grid(battle_map)
	B_GRID.position.x = x_offset
	participants = []
	for army in battling_armies:
		participants.append(army.controller)
		unsummoned_units_counter += army.units_data.size()

	participant_idx = ATTACKER
	current_participant = participants[participant_idx]

	fighting_units = [[],[]]
	battle_ui.load_armies(battling_armies)
	display_unit_summon_cards() # first player (attacker)

	current_participant.your_turn()

func load_replay(path : String):
	var replay = load(path) as BattleReplay
	assert(replay != null)
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

func replay_move_delay():
	await get_tree().create_timer(CFG.bot_speed_frames/60).timeout
	while IM.is_game_paused() or CFG.bot_speed_frames == CFG.BotSpeed.FREEZE:
		await get_tree().create_timer(0.1).timeout
		if not battle_is_ongoing:
			return # terminating battle while watching


func switch_participant_turn():
	participant_idx += 1
	participant_idx %= participants.size()
	current_participant = participants[participant_idx]

	while unsummoned_units_counter > 0 \
		and get_not_summoned_units(current_participant).size() == 0:
		participant_idx += 1
		participant_idx %= participants.size()
		current_participant = participants[participant_idx]

	selected_unit = null  # disable player to move another players units
	battle_ui.on_player_selected(current_participant)

	if battle_is_ongoing:
		current_participant.your_turn()


func grid_input(coord : Vector2i) -> void:
	"""
	input redirection (based on current ) verification
	"""

	if is_during_summoning_phase(): # Summon phase
		_grid_input_summon(coord)
		return

	if select_unit(coord) or selected_unit == null:
		# selected a new unit or wrong input which didn't select any ally unit
		return

	# is_legal_move() returns false as -1 0-5 direction for unit to move
	var side : int = is_legal_move(coord)
	if side == MOVE_IS_INVALID: # spot is empty + we aren't hitting a shield
		return

	selected_unit.set_selected(false)
	var move_info = MoveInfo.make_move(selected_unit.coord, coord)
	if NET.client:
		NET.client.queue_request_move(move_info)
		return # dont perform move, send it to server
	_replay.record_move(move_info)
	_replay.save()
	if NET.server:
		NET.server.broadcast_move(move_info)
	move_unit(selected_unit, coord, side)
	switch_participant_turn()

func perform_ai_move(move_info : MoveInfo):
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

func get_units(player : Player) -> Array[UnitForm]:
	for army_idx in range(fighting_units.size()):
		if participants[army_idx] == player:
			var typed : Array[UnitForm] = []
			typed.assign(fighting_units[army_idx])
			return typed
	return []


func select_unit(coord : Vector2i) -> bool:
	"""
	* Select friendly UnitForm on a given coord
	*
	* @return true if unit has been selected in this operation
	"""

	var new_selection : UnitForm = B_GRID.get_unit(coord)
	if (new_selection != null && new_selection.controller == current_participant):
		if selected_unit:
			selected_unit.set_selected(false)
		selected_unit = new_selection
		selected_unit.set_selected(true)
		#print("You have selected a UnitForm")
		return true

	return false

## Returns `MOVE_IS_INVALID` if move is incorrect
## or a turn direction `E.GridDirections` if move is correct
func is_legal_move(coord : Vector2i, bot_unit : UnitForm = null) -> int:
	"""
		Function checks 2 things:
		1 Target coord is a Neighbor of a selected_unit
		2 if selected_unit doesn't have push symbol on it's front (none currently have it yet)
			Target coord doesn't contain an Enemy UnitForm with a shield pointing at our selected_unit

		@param coord target coord for selected_unit to move to
		@param BotUnit optional parameter for AI that replaces selected_unit with BotUnit
		@return result_side -1 if move is illegal, direction of the move if it is
	"""
	if bot_unit != null:
		selected_unit = bot_unit  # Locally replaces UnitForm for Bot legal move search

	# 1
	var move_direction = GridManager.adjacent_side_direction(selected_unit.coord, coord)
	if move_direction == null:
		return MOVE_IS_INVALID

	#print(move_direction)
	# 2
	var enemy_unit = B_GRID.get_unit(coord)
	if enemy_unit == null:  # Is there a UnitForm in this spot?
		return move_direction

	match selected_unit.symbols[0]:
		E.Symbols.EMPTY:
			return MOVE_IS_INVALID
		E.Symbols.SHIELD:
			return MOVE_IS_INVALID # selected_unit can't deal with enemy_unit
		E.Symbols.PUSH:
			return move_direction # selected_unit ignores enemy_unit Shield
		_:
			pass
	# Does enemy_unit has a shield?
	if enemy_unit.get_symbol(move_direction + 3) == E.Symbols.SHIELD:
		return MOVE_IS_INVALID

	return move_direction


func move_unit(unit, end_coord : Vector2i, side: int) -> void:
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

	unit.turn(side) # 1

	#TODO: if shields: # maybe check for every unit
	if counter_attack_damage(unit):
		kill_unit(unit)
		if not battle_is_ongoing:   # TEMP
			end_of_battle()
		return

	unit_action(unit)
	#TODO wait half a second
	if not battle_is_ongoing:   # TEMP
		end_of_battle()
		return

	B_GRID.change_unit_coord(unit, end_coord)

	if counter_attack_damage(unit):
		kill_unit(unit)
		if not battle_is_ongoing:   # TEMP
			end_of_battle()
		return


	unit_action(unit)

	if not battle_is_ongoing:  # TEMP
		end_of_battle()


func counter_attack_damage(target : UnitForm) -> bool:
	# Returns true is Enemy spear can kill the target
	var units = B_GRID.adjacent_units(target.coord)

	for side in range(6):
		if (units[side] != null && units[side].controller != target.controller):

			if (target.get_symbol(side) == E.Symbols.SHIELD):  # Do we have a shield?
				continue

			if (units[side].get_symbol(side + 3) == E.Symbols.SPEAR): # Does enemy has a spear?
				return true
	return false


func kill_unit(target) -> void:
	for units in fighting_units:
		if units[0].controller == target.controller:
			units.erase(target)
			break

	B_GRID.remove_unit(target)

	var armies_left_alive : Array[int] = []
	for army_idx in range(fighting_units.size()):
		if fighting_units[army_idx].size() > 0:
			armies_left_alive.append(army_idx)
		else:
			battling_armies[army_idx].alive = false


	if armies_left_alive.size() < 2:
		battle_is_ongoing = false


func unit_action(unit : UnitForm) -> void:
	var units = B_GRID.adjacent_units(unit.coord)

	for side in range(6):
		var unit_weapon = unit.get_symbol(side)

		match unit_weapon:
			E.Symbols.EMPTY, E.Symbols.SHIELD:
				continue # We don't have any weapon
			E.Symbols.BOW:
				var target = B_GRID.get_shot_target(unit.coord, side)
				if target == null:
					continue # no target

				if target.controller == unit.controller:
					continue # no friendly fire

				if (target.get_symbol(side + 3) != E.Symbols.SHIELD): # Does Enemy has a shield?
					kill_unit(target)
				continue
			_:
				pass


		if (units[side] == null or units[side].controller == unit.controller):
			# no one to hit
			continue

		var enemy_unit = units[side]

		if unit_weapon == E.Symbols.PUSH:

			# PUSH LOGIC
			var distant_tile_type = B_GRID.get_distant_tile_type(unit.coord, side, 2)

			if distant_tile_type == "sentinel":  # Pushing outside the map
				# Kill
				kill_unit(enemy_unit)
				continue


			var target = B_GRID.get_distant_unit(unit.coord, side, 2)

			if target != null: # Spot isn't empty
				kill_unit(enemy_unit)
				continue

			B_GRID.change_unit_coord(enemy_unit, B_GRID.get_distant_coord(unit.coord, side, 2))
			if counter_attack_damage(enemy_unit): # Simple push
				kill_unit(enemy_unit)
			continue



		# Rotation is based on where the unit is pointing toward


		if enemy_unit.get_symbol(side + 3) != E.Symbols.SHIELD:# Does Enemy has a shield?
			kill_unit(units[side])

#endregion


#region End Battle

func get_battle_result() -> String:
	# TODO TEMP
	# Add option to return "ongoing"
	return battle_result


func close_battle() -> void:
	# delete all data related to battle
	IM.switch_camera()
	battle_ui.hide()

	B_GRID.reset_data()
	battle_is_ongoing =  false
	battle_result = NO_BATTLE
	current_participant = null
	for child in get_children():
		child.queue_free()


func end_of_battle() -> void:
	battle_is_ongoing = false
	var armies_left_alive : Array[int] = [] # TEMP
	for army_idx in range(fighting_units.size()):
		if fighting_units[army_idx].size() > 0:
			armies_left_alive.append(army_idx)
		else:
			battling_armies[army_idx].alive = false

	var winner_army = battling_armies[armies_left_alive[0]]
	var winner_player = winner_army.controller
	print(winner_player.player_name + " won")
	battle_result = ATTACKER_WIN if winner_player == participants[ATTACKER] \
			else DEFENDER_WIN

	close_battle()
	if WM.selected_hero == null:
		print("end of test battle")
		IM.go_to_main_menu()
		return
	WM.end_of_battle()

#endregion


#region Summon Phase

func is_during_summoning_phase() -> bool:
	return unsummoned_units_counter > 0


func _grid_input_summon(coord : Vector2i):
	"""
	* Units are placed by the players in subsequent order on their chosen "Starting Locations"
	* inside the area of the gameplay board.
	"""
	if battle_ui.selected_unit == null:
		return # no unit selected

	if not is_legal_summon_coord(coord, current_participant):
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


func is_legal_summon_coord(coord : Vector2i, player: Player) -> bool:
	var coord_tile_type = B_GRID.get_tile_type(coord)
	var idx = participants.find(player)
	var is_correct_spawn =\
		(coord_tile_type == "red_spawn" && idx == 0) or \
		(coord_tile_type == "blue_spawn"&& idx == 1)
	return is_correct_spawn and B_GRID.get_unit(coord) == null


func summon_unit(unit_data : DataUnit, coord : Vector2i) -> void:
	"""
		Summon currently selected unit to a Gameplay Board

		@param coord coordinate, on which UnitForm will be summoned
	"""
	#B_GRID.change_unit_coord(selected_unit, coord)
	var unit : UnitForm = CFG.UNIT_FORM_SCENE.instantiate()
	unit.apply_template(unit_data)
	unit.controller = current_participant

	fighting_units[participant_idx].append(unit)
	add_child(unit)
	B_GRID.change_unit_coord(unit, coord)

	if participant_idx == ATTACKER:
		unit.turn(3, true)
	else:
		unit.turn(0, true)

	unsummoned_units_counter -= 1
	battle_ui.unit_summoned(not is_during_summoning_phase(), unit_data)


func get_not_summoned_units(player:Player) -> Array[DataUnit]:
	return battle_ui.get_army(player).units_data


func get_summon_tiles(player:Player) -> Array[TileForm]:
	var summon_tiles = B_GRID.get_all_field_coords()\
		.filter(func isOk(coord) : return is_legal_summon_coord(coord, player))\
		.map(func getTile(coord) : return B_GRID.get_tile(coord))
	var typed:Array[TileForm] = []
	typed.assign(summon_tiles)
	return typed

#endregion


#region Battle Setup


func display_unit_summon_cards(shown_participant : Player = current_participant):
	# lists all selected participant units at the bottom of the screen
	battle_ui.on_player_selected(shown_participant)


#endregion

#region cheats/debug
func force_win_battle():
	for army_idx in range(fighting_units.size()):
		if army_idx == participant_idx:
			continue
		for unit_idx in range(fighting_units[army_idx].size() - 1, -1, -1):
			kill_unit(fighting_units[army_idx][unit_idx])

func force_surrender():
	for unit_idx in range(fighting_units[participant_idx].size() - 1, -1, -1):
		kill_unit(fighting_units[participant_idx][unit_idx])
#endregion
