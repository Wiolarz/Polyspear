# Singleton - BM

extends Node


const ATTACKER = 0
const DEFENDER = 1

#region Setup variables

var commanders = []  # Hero objects that take part in battle (based on them we get players who control the battle)
var participants : Array[Player] = []
var battling_armies : Array[Army]


# TODO to be changed to approach suitable for more battle participants than 2
var armies_unit_scenes : Array = [] # Array[Array[PackedScene]]
var attacker_unit_scenes : Array[PackedScene]
var defender_unit_scenes : Array[PackedScene]

#endregion

#region Variables
var current_participant : Player
var participant_idx : int = ATTACKER

var selected_unit : AUnit

var fighting_units : Array = [] # Array[Array[AUnit]]
var attacker_units = []
var defender_units = []

var UnitsLeftToBeSummoned : int # set at the start of the during placement "summon" stage -> battle start after this number reaches 0

#endregion






#region Tools

func is_legal_move(cord : Vector2i, BotUnit : AUnit = null) -> int:
	"""
	 Function checks 2 things:
	 * 1 Target cord is a Neighbour of a selected_unit
	 * 2 if selected_unit doesn't have push symbol on it's front (none currently have it yet)
	 *	 Target cord doesn't contatin an Enemy Unit with a shield pointing at our selected_unit
	 * 
	 * @param cord
	 * @param ResultSide
	 * @return True if selected Unit can move on a given cord
	 """
	if BotUnit != null:
		selected_unit = BotUnit  # Locally replacs Unit for Bot legal move search

	# 1
	var ResultSide = GridManager.adjacent_side(selected_unit.cord, cord)  
	if ResultSide == null:
		return -1

	#print(ResultSide)
	# 2
	var EnemyUnit = B_GRID.get_unit(cord)
	if EnemyUnit == null:  # Is there a Unit in this spot?
		return ResultSide
	
	match selected_unit.Symbols[0]:
		E.Symbols.EMPTY:
			return -1
		E.Symbols.SHIELD:
			return -1 # selected_unit can't deal with EnemyUnit
		E.Symbols.PUSH:
			return ResultSide # selected_unit ignores EnemyUnit Shield
		_:
			pass
	# Does EnemyUnit has a shield?
	if EnemyUnit.get_symbol(ResultSide + 3) == E.Symbols.SHIELD:
		return -1

	return ResultSide


func move_unit(Unit, EndCord : Vector2i, side: int) -> void:
	# Move General function
	"""
	 * Move this unit to EndCord
	 *
	 * @param EndCord Position at which unit will be placed
	 """

	Unit.Rotate(side) # 1

	#TODO: if shields: # maybe check for every unit
	if counter_attack_damage(Unit):
		kill_unit(Unit)
		return


	unit_action(selected_unit)
	#TODO wait half a second


	B_GRID.ChangeUnitPosition(Unit, EndCord)

	if counter_attack_damage(Unit):
		kill_unit(Unit)
		return
		
		
	unit_action(selected_unit)


func counter_attack_damage(Target : AUnit) -> bool:
	# Returns true is Enemy spear can kill the Target
	var Units = B_GRID.AdjacentUnits(Target.cord)

	for side in range(6):
		if (Units[side] != null && Units[side].controller != Target.controller):

			if (Target.get_symbol(side) == E.Symbols.SHIELD):  # Do we have a shield?
				continue

			if (Units[side].get_symbol(side + 3) == E.Symbols.SPEAR): # Does enemy has a spear?
				return true
	return false



func kill_unit(Target) -> void:
	for units in fighting_units:
		if units[0].controller == Target.controller:
			units.erase(Target)
			break
	
	B_GRID.RemoveUnit(Target)

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
	
		

	


func unit_action(Unit) -> void:
	var Units = B_GRID.AdjacentUnits(Unit.cord)

	for side in range(6):
		var UnitWeapon = Unit.get_symbol(side)

		match UnitWeapon:
			E.Symbols.EMPTY:
				continue #####################################################################################TODO check if we could fix it
			E.Symbols.SHIELD:
				continue # We don't have a weapon

			E.Symbols.BOW:
				var Target = B_GRID.GetShotTarget(Unit.cord, side)
				if Target == null:
					continue

				if Target.controller == Unit.controller:
					continue

				if (Target.get_symbol(side + 3) != E.Symbols.SHIELD): # Does Enemy has a shield?
					kill_unit(Target)
				continue
			_:
				pass
			

		if (Units[side] == null or Units[side].controller == Unit.controller):
			# no one to hit
			continue

		var EnemyUnit = Units[side]

		if UnitWeapon == E.Symbols.PUSH:

			# PUSH LOGIC
			var TargetTileType = B_GRID.GetDistantTileType(Unit.cord, side, 2)

			if TargetTileType == E.HexTileType.SENTINEL:  # Pushing outside the map
				# Kill
				kill_unit(EnemyUnit)
				continue


			var Target = B_GRID.GetDistantUnit(Unit.cord, side, 2)

			if Target != null: # Spot isn't empty
				kill_unit(EnemyUnit)
				continue

			B_GRID.ChangeUnitPosition(EnemyUnit, B_GRID.GetDistantCord(Unit.cord, side, 2))
			if counter_attack_damage(EnemyUnit): # Simple push	
				kill_unit(EnemyUnit)
			continue
		


		# Rotation is based on where the unit is pointing toward


		if EnemyUnit.get_symbol(side + 3) != E.Symbols.SHIELD:# Does Enemy has a shield?
			kill_unit(Units[side])
		
				



func select_unit(cord : Vector2i) -> bool:
	"""
	 * Select friendly Unit on a given cord
	 *
	 * @return true if unit has been selected in this operation
	 """

	var NewSelection : AUnit = B_GRID.get_unit(cord)
	if (NewSelection != null && NewSelection.controller == current_participant):
		selected_unit = NewSelection
		#print("You have selected a Unit")

		return true

	return false

#endregion


#region Main Functions

func clear_battle():
	current_participant = null
	for unit in get_children():
		unit.queue_free()
	for tile in B_GRID.get_children():
		tile.queue_free()

func end_of_battle():
	clear_battle()
	if WM.selected_hero == null:
		print("end of test battle")
		IM.go_to_main_menu()
		return
	WM.end_of_battle()


func switch_participant_turn():
	if participant_idx + 1 == participants.size():
		participant_idx = ATTACKER
	else:
		participant_idx += 1
	
	current_participant = participants[participant_idx]
		




func grid_input(cord : Vector2i) -> void:

	if select_unit(cord) or selected_unit == null:
		return # selected a new unit or wrong input which didn't select any ally unit


	if UnitsLeftToBeSummoned > 0: # Summon phase
		"""
		* Units are placed by the players in subsequent order on their chosen "Starting Locations"
		* inside the area of the gameplay board.
		"""
		summon_unit(cord)
	else:  # Gameplay phase
		gameplay(cord)

	selected_unit = null  # IMPORTANT






func gameplay(cord : Vector2i) -> void:
	#print("Gameplay is working")

	var side = is_legal_move(cord) # is_legal_move() returns false as -1 0-5 direction for unit to move
	if side != -1: # spot is empty + we aren't hitting a shield
		# 1 Rotate

		# 2 Check for Spear

		# 3 Actions

		# 4 Move

		# 5 Check for Spear

		# 6 Actions
		move_unit(selected_unit, cord, side)


		switch_participant_turn()
	


func summon_unit(cord : Vector2i) -> void:
	"""
	 * Summon currently selected unit to a Gameplay Board
	 *
	 *
	 * @param cord cordinate, on which Unit will be summoned
	 """
	

	# check if unit is already summoned
	var SelectedUnitTileType = B_GRID.get_tile_type(selected_unit.cord)

	if SelectedUnitTileType != E.HexTileType.SENTINEL:
		#print("This Unit has been already summoned")
		return
	

	var SelectedHexType = B_GRID.get_tile_type(cord)

	var bSelectedcurrent_participantSpawn = \
		(SelectedHexType == E.HexTileType.ATTACKER_SPAWN && participant_idx == 0) or \
		(SelectedHexType == E.HexTileType.DEFENDER_SPAWN && participant_idx == 1)

	if not bSelectedcurrent_participantSpawn:
		#print("Thats a wrong summon location")  # TODO: Don't reset selected_unit
		return

	#print("You summoned a Unit")

	# TeleportUnit(cord)
	B_GRID.ChangeUnitPosition(selected_unit, cord)

	if participant_idx == ATTACKER:
		selected_unit.Rotate(0)
	else:
		selected_unit.Rotate(3)


	switch_participant_turn()

	UnitsLeftToBeSummoned -= 1

#endregion

#region Battle Setup


func spawn_units() -> void:
	"""
	* Placing Units used in combat on their "Spawn Points" near the area of the gameplay board where they are visible to the players.
	"""

	UnitsLeftToBeSummoned = 0 
	for army in armies_unit_scenes:
		UnitsLeftToBeSummoned += army.size()
	
	var spawn_cord

	# spawn armies units
	for army_idx in range(armies_unit_scenes.size()):
		var army = armies_unit_scenes[army_idx]
		fighting_units.append([])
		for unit_idx in range(army.size()):
			var newUnitScene = army[unit_idx]
			var new_unit = newUnitScene.instantiate()
			add_child(new_unit) # jako element sceny
			
			fighting_units[army_idx].append(new_unit)

			new_unit.controller = participants[army_idx]

			if army_idx == ATTACKER:
				spawn_cord = B_GRID.AttackerTiles[unit_idx].cord # Get spawn location
				spawn_cord += B_GRID.DIRECTIONS[3]  # Move to a spot outside of the map near spawn point
			elif army_idx == DEFENDER:
				spawn_cord = B_GRID.DefenderTiles[unit_idx].cord
				spawn_cord += B_GRID.DIRECTIONS[0]

			B_GRID.ChangeUnitPosition(new_unit, spawn_cord) # Adding Unit to the Gameplay Array



func start_battle(new_armies : Array[Army], battle_map : BattleMap):
	WM.raging_battle = true
	battling_armies = new_armies

	B_GRID.generate_grid(battle_map)

	for army in battling_armies:
		participants.append(army.controller)
		armies_unit_scenes.append(army.unit_set.Units)

	current_participant = participants[ATTACKER]
	participant_idx = ATTACKER

	spawn_units()
	
	
#endregion
