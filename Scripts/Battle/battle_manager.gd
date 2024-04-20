# Singleton - BM
extends Node

var battle_ui : BattleUI = null

const ATTACKER = 0
const DEFENDER = 1

const AI_MOVE_DELAY = 0.7 # seconds

#region Setup variables

var participants : Array[Player] = []
var battling_armies : Array[Army]

var armies_units_data : Array = [] # Array[Array[PackedScene]]

func _ready():
	battle_ui = load("res://Scenes/UI/BattleUi.tscn").instantiate()
	UI.add_custom_screen(battle_ui)

#endregion


#region Variables
var battle_is_ongoing : bool = false

var current_participant : Player
var participant_idx : int = ATTACKER

var selected_unit : Unit

var fighting_units : Array = [[],[]] # Array[Array[Unit]]

var unsummoned_units_counter : int # set at the start of the during placement "summon" stage -> battle start after this number reaches 0

#endregion


#region Main Functions

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

	if unsummoned_units_counter > 0: # Summon phase
		_grid_input_summon(coord)
		return

	if select_unit(coord) or selected_unit == null:
		# selected a new unit or wrong input which didn't select any ally unit
		return

	var side : int = is_legal_move(coord) # is_legal_move() returns false as -1 0-5 direction for unit to move
	if side == -1: # spot is empty + we aren't hitting a shield
		return

	selected_unit.set_selected(false)
	move_unit(selected_unit, coord, side)
	switch_participant_turn()

func perform_ai_move( move :MoveInfo,  _me: Player):
	if move.move_type == MoveInfo.TYPE_MOVE:
		var unit = B_GRID.get_unit(move.move_source)
		var dir = GridManager.adjacent_side(unit.coord, move.target_tile_coord)
		move_unit(unit, move.target_tile_coord, dir)
		await get_tree().create_timer(AI_MOVE_DELAY).timeout
		switch_participant_turn()
		return
	if move.move_type == MoveInfo.TYPE_SUMMON:
		summon_unit(move.summon_unit, move.target_tile_coord)
		await get_tree().create_timer(AI_MOVE_DELAY).timeout
		switch_participant_turn()
		return
	assert(false, "Move move_type not supported in perform")

#endregion


#region Tools

func get_units(player:Player) -> Array[Unit]:
	for armyIdx in range(fighting_units.size()):
		if participants[armyIdx] == player:
			var typed:Array[Unit] = []
			typed.assign(fighting_units[armyIdx])
			return typed
	return []


func select_unit(coord : Vector2i) -> bool:
	"""
	 * Select friendly Unit on a given coord
	 *
	 * @return true if unit has been selected in this operation
	 """

	var new_selection : Unit = B_GRID.get_unit(coord)
	if (new_selection != null && new_selection.controller == current_participant):
		if selected_unit:
			selected_unit.set_selected(false)
		selected_unit = new_selection
		selected_unit.set_selected(true)
		#print("You have selected a Unit")
		return true

	return false


func is_legal_move(coord : Vector2i, BotUnit : Unit = null) -> int:
	"""
		Function checks 2 things:
		1 Target coord is a Neighbour of a selected_unit
		2 if selected_unit doesn't have push symbol on it's front (none currently have it yet)
			Target coord doesn't contatin an Enemy Unit with a shield pointing at our selected_unit

		@param coord target coord for selected_unit to move to
		@param BotUnit optional parameter for AI that replaces selected_unit with BotUnit
		@return result_side -1 if move is illegal, direction of the move if it is
	"""
	if BotUnit != null:
		selected_unit = BotUnit  # Locally replacs Unit for Bot legal move search

	# 1
	var result_side = GridManager.adjacent_side(selected_unit.coord, coord)
	if result_side == null:
		return -1

	#print(result_side)
	# 2
	var enemy_unit = B_GRID.get_unit(coord)
	if enemy_unit == null:  # Is there a Unit in this spot?
		return result_side

	match selected_unit.Symbols[0]:
		E.Symbols.EMPTY:
			return -1
		E.Symbols.SHIELD:
			return -1 # selected_unit can't deal with enemy_unit
		E.Symbols.PUSH:
			return result_side # selected_unit ignores enemy_unit Shield
		_:
			pass
	# Does enemy_unit has a shield?
	if enemy_unit.get_symbol(result_side + 3) == E.Symbols.SHIELD:
		return -1

	return result_side


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
		return


	unit_action(unit)
	#TODO wait half a second
	if not battle_is_ongoing:   # TEMP
		end_of_battle()
		return

	B_GRID.change_unit_coord(unit, end_coord)

	if counter_attack_damage(unit):
		kill_unit(unit)
		return


	unit_action(unit)

	if not battle_is_ongoing:  # TEMP
		end_of_battle()


func counter_attack_damage(target : Unit) -> bool:
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


func unit_action(unit : Unit) -> void:
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

func get_battle_result() -> bool:
	# TODO TEMP
	# Add option to return "ongoing"
	return true


func close_battle() -> void:
	# delete all data related to battle
	IM.switch_camera()
	battle_ui.hide()

	B_GRID.reset_data()
	battle_is_ongoing =  false
	current_participant = null
	for child in get_children():
		child.queue_free()


func end_of_battle() -> void:
	var armies_left_alive : Array[int] = [] # TEMP
	for army_idx in range(fighting_units.size()):
		if fighting_units[army_idx].size() > 0:
			armies_left_alive.append(army_idx)
		else:
			battling_armies[army_idx].alive = false

	var winner_army = battling_armies[armies_left_alive[0]]
	print(winner_army.controller.player_name + " won")

	close_battle()
	if WM.selected_hero == null:
		print("end of test battle")
		IM.go_to_main_menu()
		return
	WM.end_of_battle()

#endregion


#region Summon Phase

func _grid_input_summon(coord : Vector2i):
	"""
	* Units are placed by the players in subsequent order on their chosen "Starting Locations"
	* inside the area of the gameplay board.
	"""
	if battle_ui.selected_unit == null:
		return # no unit selected

	if is_legal_summon_coord(coord, current_participant):
		summon_unit(battle_ui.selected_unit, coord)
		switch_participant_turn()


func is_legal_summon_coord(coord : Vector2i, player: Player) -> bool:
	var coord_tile_type = B_GRID.get_tile_type(coord)
	var idx = participants.find(player)
	var is_correct_spawn =\
		(coord_tile_type == "red_spawn" && idx == 0) or \
		(coord_tile_type == "blue_spawn"&& idx == 1)
	return is_correct_spawn and B_GRID.get_unit(coord) == null


func summon_unit(unitData : DataUnit, coord : Vector2i) -> void:
	"""
		Summon currently selected unit to a Gameplay Board

		@param coord coordinate, on which Unit will be summoned
	 """
	#B_GRID.change_unit_coord(selected_unit, coord)
	var unit : Unit = load("res://Scenes/Form/UnitForm.tscn").instantiate()
	unit.apply_template(unitData)
	unit.controller = current_participant

	fighting_units[participant_idx].append(unit)
	add_child(unit)
	B_GRID.change_unit_coord(unit, coord)

	if participant_idx == ATTACKER:
		unit.turn(3, true)
	else:
		unit.turn(0, true)

	unsummoned_units_counter -= 1
	battle_ui.unit_summoned(unsummoned_units_counter == 0, unitData)


func get_not_summoned_units(player:Player) -> Array[DataUnit]:
	return battle_ui.get_army(player).units_data


func get_summon_tiles(player:Player) -> Array[HexTile]:
	var summon_tiles = B_GRID.get_all_field_coords()\
		.filter(func isOk(coord) : return is_legal_summon_coord(coord, player))\
		.map(func getTile(coord) : return B_GRID.tile_at(coord))
	var typed:Array[HexTile] = []
	typed.assign(summon_tiles)
	return typed

#endregion


#region Battle Setup

func spawn_units() -> void:
	"""
	Create unit "cards" which players will use later to summon their units on the battlefield
	"""
	fighting_units = [] # TODO MOVE TO CHECK CLEAR
	unsummoned_units_counter = 0
	for army in battling_armies:
		unsummoned_units_counter += army.units_data.size()

	# spawn armies units cards in battle UI
	for army in battling_armies:
		var new_army_unit_nodes = []
		fighting_units.append(new_army_unit_nodes)


	battle_ui.load_armies(battling_armies)
	display_unit_summon_cards() # first player (attacker)


func display_unit_summon_cards(shown_participant : Player = current_participant):
	# lists all selected participant units at the bottom of the screen
	battle_ui.on_player_selected(shown_participant)


func start_battle(new_armies : Array[Army], battle_map : BattleMap) -> void:
	UI.go_to_custom_ui(battle_ui)
	IM.raging_battle = true
	battle_is_ongoing = true
	battling_armies = new_armies

	B_GRID.generate_grid(battle_map)
	participants = []
	for army in battling_armies:
		participants.append(army.controller)
		armies_units_data.append(army.units_data)

	current_participant = participants[ATTACKER]
	participant_idx = ATTACKER

	spawn_units()
	current_participant.your_turn()

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
