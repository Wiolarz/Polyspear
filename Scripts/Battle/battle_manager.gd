# Singleton - BM

extends Node


const ATTACKER = 0
const DEFENDER = 1

#region Setup variables

var commanders = []  # Hero objects that take part in battle (based on them we get players who control the battle)
var participants : Array[Player] = []

var AttackerBot : StateMachine
var DefenderBot : StateMachine

var AttackerUnitsTypes : Array[PackedScene]
var DefenderUnitsTypes : Array[PackedScene]

#endregion

#region Variables
var current_participant : Player
var participant_idx : int = ATTACKER

var SelectedUnit

var attacker_units = []
var defender_units = []

var UnitsLeftToBeSummoned



#endregion






#region Tools

func is_legal_move(cord : Vector2i, BotUnit : AUnit = null) -> int:
	"""
	 Function checks 2 things:
	 * 1 Target cord is a Neighbour of a SelectedUnit
	 * 2 if SelectedUnit doesn't have push symbol on it's front (none currently have it yet)
	 *	 Target cord doesn't contatin an Enemy Unit with a shield pointing at our SelectedUnit
	 * 
	 * @param cord
	 * @param ResultSide
	 * @return True if selected Unit can move on a given cord
	 """
	if BotUnit != null:
		SelectedUnit = BotUnit  # Locally replacs Unit for Bot legal move search

	# 1
	var ResultSide = B_GRID.AdjacentSide(SelectedUnit.cord, cord)  
	if ResultSide == null:
		return -1

	#print(ResultSide)
	# 2
	var EnemyUnit = B_GRID.get_unit(cord)
	if EnemyUnit == null:  # Is there a Unit in this spot?
		return ResultSide
	
	match SelectedUnit.Symbols[0]:
		E.Symbols.EMPTY:
			return -1
		E.Symbols.SHIELD:
			return -1 # SelectedUnit can't deal with EnemyUnit
		E.Symbols.PUSH:
			return ResultSide # SelectedUnit ignores EnemyUnit Shield
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


	unit_action(SelectedUnit)
	#TODO wait half a second


	B_GRID.ChangeUnitPosition(Unit, EndCord)

	if counter_attack_damage(Unit):
		kill_unit(Unit)
		return
		
		
	unit_action(SelectedUnit)


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
	if (Target.controller == participants[DEFENDER]):
		defender_units.erase(Target)
	else:
		attacker_units.erase(Target)
	
	B_GRID.RemoveUnit(Target)

	if defender_units.size() == 0:
		BUS.Attacker_wins += 1
		print("Attacker won" + "D:" + str(BUS.Defender_wins) + " A:" + str(BUS.Attacker_wins))
	elif attacker_units.size() == 0:
		BUS.Defender_wins += 1
		print("Defender won_" + "D:" + str(BUS.Defender_wins) + " A:" + str(BUS.Attacker_wins))

	
	if attacker_units.size() == 0 or defender_units.size() == 0:
		end_of_battle()

	
func end_of_battle():
	clear_battle()
	WM.end_of_battle()

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
		SelectedUnit = NewSelection
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




func switch_participant_turn():
	if participant_idx + 1 == participants.size():
		participant_idx = ATTACKER
	else:
		participant_idx += 1
	
	current_participant = participants[participant_idx]
		




func input_listener(cord : Vector2i) -> void:

	if select_unit(cord) or SelectedUnit == null:
		return # selected a new unit or wrong input which didn't select any ally unit


	if UnitsLeftToBeSummoned > 0: # Summon phase
		"""
		* Units are placed by the players in subsequent order on their chosen "Starting Locations"
		* inside the area of the gameplay board.
		"""
		summon_unit(cord)
	else:  # Gameplay phase
		gameplay(cord)

	SelectedUnit = null  # IMPORTANT






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
		move_unit(SelectedUnit, cord, side)
		#print(FString::Printf(TEXT("DIRECTION_%d"), side))
		#testKillUnit(cord)
		
		#B_GRID.ChangeUnitPosition(SelectedUnit, cord)
		#print(FString::Printf(TEXT("_%d"), side))
		#.RotateUnit(SelectedUnit, side)

		switch_participant_turn()
	


func summon_unit(cord : Vector2i) -> void:
	"""
	 * Summon currently selected unit to a Gameplay Board
	 *
	 *
	 * @param cord cordinate, on which Unit will be summoned
	 """
	

	# check if unit is already summoned
	var SelectedUnitTileType = B_GRID.get_tile_type(SelectedUnit.cord)

	if SelectedUnitTileType != E.HexTileType.SENTINEL:
		#print("This Unit has been already summoned")
		return
	

	var SelectedHexType = B_GRID.get_tile_type(cord)

	var bSelectedcurrent_participantSpawn = \
		(SelectedHexType == E.HexTileType.ATTACKER_SPAWN && participant_idx == 0) or \
		(SelectedHexType == E.HexTileType.DEFENDER_SPAWN && participant_idx == 1)

	if not bSelectedcurrent_participantSpawn:
		#print("Thats a wrong summon location")  # TODO: Don't reset SelectedUnit
		return

	#print("You summoned a Unit")

	# TeleportUnit(cord)
	B_GRID.ChangeUnitPosition(SelectedUnit, cord)

	if participant_idx == ATTACKER:
		SelectedUnit.Rotate(0)
	else:
		SelectedUnit.Rotate(3)


	switch_participant_turn()

	UnitsLeftToBeSummoned -= 1

#endregion

#region Battle Setup


func spawn_units() -> void:
	"""
	* Placing Units used in combat on their "Spawn Points" near the area of the gameplay board where they are visible to the players.
	"""

	UnitsLeftToBeSummoned = AttackerUnitsTypes.size() + DefenderUnitsTypes.size()  # Flag that manages the state of the game
	
	# RESET DATA
	attacker_units = []
	defender_units = []
	SelectedUnit = null
	
	var SpawnCord

	# spawning attacker units
	for i in range(AttackerUnitsTypes.size()):
		var newUnitScene = AttackerUnitsTypes[i]
		var new_unit = newUnitScene.instantiate()
		add_child(new_unit) # jako element sceny
		attacker_units.append(new_unit)

		new_unit.controller = participants[ATTACKER]

		SpawnCord = B_GRID.AttackerTiles[i].cord # Get spawn location
		SpawnCord += B_GRID.DIRECTIONS[3]  # Move to a spot outside of the map near spawn point

		B_GRID.ChangeUnitPosition(new_unit, SpawnCord) # Adding Unit to the Gameplay Array
		

	# spawning defender units
	for i in range(DefenderUnitsTypes.size()):
		var newUnitScene = DefenderUnitsTypes[i]
		var new_unit = newUnitScene.instantiate()
		add_child(new_unit) # jako element sceny
		defender_units.append(new_unit)

		new_unit.controller = participants[DEFENDER]

		SpawnCord = B_GRID.DefenderTiles[i].cord # Get spawn location
		SpawnCord += B_GRID.DIRECTIONS[0] # Move to a spot outside of the map near spawn point

		B_GRID.ChangeUnitPosition(new_unit, SpawnCord) # Adding Unit to the Gameplay Array

	SelectedUnit = null


func start_battle(new_armies : Array[Army]):
	for army in new_armies:
		participants.append(army.controller)
	current_participant = participants[ATTACKER]
	participant_idx = ATTACKER

	AttackerUnitsTypes = new_armies[ATTACKER].unit_set.Units
	DefenderUnitsTypes = new_armies[DEFENDER].unit_set.Units

	spawn_units()
	
	
#endregion
