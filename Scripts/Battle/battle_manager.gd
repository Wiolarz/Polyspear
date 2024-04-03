# Singleton - BM
extends Node

var battle_ui : BattleUI = null

const ATTACKER = 0
const DEFENDER = 1


#region Setup variables

var participants : Array[Player] = []
var battling_armies : Array[Army]

var armies_units_data : Array = [] # Array[Array[PackedScene]]


#endregion


#region Variables
var current_participant : Player
var participant_idx : int = ATTACKER

var selected_unit : AUnit

var fighting_units : Array = [[],[]] # Array[Array[AUnit]]

var unsummoned_units_counter : int # set at the start of the during placement "summon" stage -> battle start after this number reaches 0

#endregion


func _ready():
	battle_ui = load("res://Scenes/UI/BattleUi.tscn").instantiate()
	add_child(battle_ui)
	battle_ui.hide()

#region Tools

func is_legal_move(cord : Vector2i, BotUnit : AUnit = null) -> int:
	"""
		Function checks 2 things:
		1 Target cord is a Neighbour of a selected_unit
		2 if selected_unit doesn't have push symbol on it's front (none currently have it yet)
			Target cord doesn't contatin an Enemy Unit with a shield pointing at our selected_unit
		
		@param cord target cord for selected_unit to move to
		@param BotUnit optional parameter for AI that replaces selected_unit with BotUnit
		@return result_side -1 if move is illegal, direction of the move if it is
	"""
	if BotUnit != null:
		selected_unit = BotUnit  # Locally replacs Unit for Bot legal move search

	# 1
	var result_side = GridManager.adjacent_side(selected_unit.cord, cord)  
	if result_side == null:
		return -1

	#print(result_side)
	# 2
	var enemy_unit = B_GRID.get_unit(cord)
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


func move_unit(unit, end_cord : Vector2i, side: int) -> void:
	# Move General function
	"""
		Turns unit to @side then Moves unit to end_cord
		
		1 Turn
		2 Check for counter attack damage
		3 Actions
		4 Move to another tile
		5 Check for counter attack damage
		6 Actions

		@param end_cord Position at which unit will be placed
	"""

	unit.turn(side) # 1

	#TODO: if shields: # maybe check for every unit
	if counter_attack_damage(unit):
		kill_unit(unit)
		return


	unit_action(unit)
	#TODO wait half a second


	B_GRID.change_unit_cord(unit, end_cord)

	if counter_attack_damage(unit):
		kill_unit(unit)
		return
		
		
	unit_action(unit)


func counter_attack_damage(target : AUnit) -> bool:
	# Returns true is Enemy spear can kill the target
	var units = B_GRID.adjacent_units(target.cord)

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
		var winner_army = battling_armies[armies_left_alive[0]]
		print(winner_army.controller.player_name + " won")
		end_of_battle()
	
		
func unit_action(unit : AUnit) -> void:
	var units = B_GRID.adjacent_units(unit.cord)

	for side in range(6):
		var unit_weapon = unit.get_symbol(side)

		match unit_weapon:
			E.Symbols.EMPTY, E.Symbols.SHIELD:
				continue # We don't have any weapon
			E.Symbols.BOW:
				var target = B_GRID.get_shot_target(unit.cord, side)
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
			var distant_tile_type = B_GRID.get_distant_tile_type(unit.cord, side, 2)

			if distant_tile_type == "sentinel":  # Pushing outside the map
				# Kill
				kill_unit(enemy_unit)
				continue


			var target = B_GRID.get_distant_unit(unit.cord, side, 2)

			if target != null: # Spot isn't empty
				kill_unit(enemy_unit)
				continue

			B_GRID.change_unit_cord(enemy_unit, B_GRID.get_distant_cord(unit.cord, side, 2))
			if counter_attack_damage(enemy_unit): # Simple push	
				kill_unit(enemy_unit)
			continue
		


		# Rotation is based on where the unit is pointing toward


		if enemy_unit.get_symbol(side + 3) != E.Symbols.SHIELD:# Does Enemy has a shield?
			kill_unit(units[side])
		
				
func select_unit(cord : Vector2i) -> bool:
	"""
	 * Select friendly Unit on a given cord
	 *
	 * @return true if unit has been selected in this operation
	 """

	var new_selection : AUnit = B_GRID.get_unit(cord)
	if (new_selection != null && new_selection.controller == current_participant):
		selected_unit = new_selection
		selected_unit.set_selected(true)
		#print("You have selected a Unit")
		return true

	return false

#endregion


#region Main Functions

func switch_participant_turn():
	if participant_idx + 1 == participants.size():
		participant_idx = ATTACKER
	else:
		participant_idx += 1
	
	current_participant = participants[participant_idx]
	selected_unit = null  # disable player to move another players units
	battle_ui.on_player_selected(current_participant)

func grid_input(cord : Vector2i) -> void:
	"""
	input redirection (based on current ) verification
	"""
	
	if unsummoned_units_counter > 0: # Summon phase
		_grid_input_summon(cord)
		return
	
	if select_unit(cord) or selected_unit == null:
		# selected a new unit or wrong input which didn't select any ally unit
		return 

	var side : int = is_legal_move(cord) # is_legal_move() returns false as -1 0-5 direction for unit to move
	if side == -1: # spot is empty + we aren't hitting a shield
		return
	
	selected_unit.set_selected(false)
	move_unit(selected_unit, cord, side)
	switch_participant_turn()

func _grid_input_summon(cord : Vector2i):
	"""
	* Units are placed by the players in subsequent order on their chosen "Starting Locations"
	* inside the area of the gameplay board.
	"""
	if battle_ui.selected_unit == null:
		return # no unit selected

	if is_legal_summon_cord(cord):
		summon_unit(cord)
		switch_participant_turn()

func is_legal_summon_cord(cord : Vector2i) -> bool:
	var cord_tile_type = B_GRID.get_tile_type(cord)
	var is_correct_spawn =\
		(cord_tile_type == "red_spawn" && participant_idx == 0) or \
		(cord_tile_type == "blue_spawn"&& participant_idx == 1)
	return is_correct_spawn and B_GRID.get_unit(cord) == null

func summon_unit(cord : Vector2i) -> void:
	"""
		Summon currently selected unit to a Gameplay Board

		@param cord cordinate, on which Unit will be summoned
	 """
	#B_GRID.change_unit_cord(selected_unit, cord)
	var unit : AUnit = load("res://Scenes/Form/UnitForm.tscn").instantiate()
	unit.apply_template(battle_ui.selected_unit)
	unit.controller = current_participant

	fighting_units[participant_idx].append(unit)
	add_child(unit)
	B_GRID.change_unit_cord(unit, cord)
	
	if participant_idx == ATTACKER:
		unit.turn(3)
	else:
		unit.turn(0)

	unsummoned_units_counter -= 1
	battle_ui.unit_summoned(unsummoned_units_counter == 0)

#endregion


#region End Battle

func close_battle() -> void:
	# delete all data related to battle
	IM.switch_camera()

	B_GRID.reset_data()
	
	current_participant = null
	for child in get_children():
		if child ==  battle_ui:
			continue
		child.queue_free()


func end_of_battle() -> void:
	close_battle()
	if WM.selected_hero == null:
		print("end of test battle")
		IM.go_to_main_menu()
		return
	WM.end_of_battle()

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
	
	# spawn armies units
	for army in battling_armies:
		var new_army_unit_nodes = []
		fighting_units.append(new_army_unit_nodes)
		# create scenes based on unit data


		# for unit_scene : PackedScene in army.units_data:
		# 	var new_unit : AUnit = unit_scene.instantiate()
		# 	add_child(new_unit)
			
		# 	#new_unit.visible = false
		# 	new_unit.controller = army.controller

		# 	new_army_unit_nodes.append(new_unit)

	battle_ui.load_armies(battling_armies)
	display_unit_summon_cards() # first player (attacker)



func display_unit_summon_cards(shown_participant : Player = current_participant):
	# lists all selected participant units at the bottom of the screen
	battle_ui.on_player_selected(shown_participant)


func start_battle(new_armies : Array[Army], battle_map : BattleMap) -> void:
	battle_ui.show()
	WM.raging_battle = true
	battling_armies = new_armies

	B_GRID.generate_grid(battle_map)
	participants = []
	for army in battling_armies:
		participants.append(army.controller)
		armies_units_data.append(army.units_data)

	current_participant = participants[ATTACKER]
	participant_idx = ATTACKER

	spawn_units()

#endregion
