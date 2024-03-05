class_name GameManager

extends Node


#region Variables

var GameSetupNode

var AttackerUnitsTypes : Array[PackedScene]
var DefenderUnitsTypes : Array[PackedScene]


var AttackerUnits = []
var DefenderUnits = []

var current_participant : E.Participant = E.Participant.ATTACKER

var SelectedUnit

var UnitsLeftToBeSummoned



var AttackerBot : StateMachine
var DefenderBot : StateMachine

var timer = 0



#endregion






#region Tools

func SwitchParticipantTurn():
	# Currently works only for 2 players
	if current_participant == E.Participant.ATTACKER:
		current_participant = E.Participant.DEFENDER
	else:
		current_participant = E.Participant.ATTACKER


func IsLegalMove(Cord : Vector2i, BotUnit : AUnit = null) -> int:
	"""
	 Function checks 2 things:
	 * 1 Target Cord is a Neighbour of a SelectedUnit
	 * 2 if SelectedUnit doesn't have push symbol on it's front (none currently have it yet)
	 *	 Target Cord doesn't contatin an Enemy Unit with a shield pointing at our SelectedUnit
	 * 
	 * @param Cord
	 * @param ResultSide
	 * @return True if selected Unit can move on a given Cord
	 """
	if BotUnit != null:
		SelectedUnit = BotUnit  # Locally replacs Unit for Bot legal move search

	# 1
	var ResultSide = B_GRID.AdjacentSide(SelectedUnit.CurrentCord, Cord)  
	if ResultSide == null:
		return -1

	#print(ResultSide)
	# 2
	var EnemyUnit = B_GRID.GetUnit(Cord)
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
	if EnemyUnit.GetSymbol(ResultSide + 3) == E.Symbols.SHIELD:
		return -1

	return ResultSide


func MoveUnit(Unit, EndCord : Vector2i, side: int) -> void:
	# Move General function
	"""
	 * Move this unit to EndCord
	 *
	 * @param EndCord Position at which unit will be placed
	 """

	Unit.Rotate(side) # 1

	#TODO: if shields: # maybe check for every unit
	if EnemyDamage(Unit):
		KillUnit(Unit)
		return


	UnitAction(SelectedUnit)
	#TODO wait half a second


	B_GRID.ChangeUnitPosition(Unit, EndCord)

	if EnemyDamage(Unit):
		KillUnit(Unit)
		return
		
		
	UnitAction(SelectedUnit)


func EnemyDamage(Target : AUnit) -> bool:
	# Returns true is Enemy spear can kill the Target
	var Units = B_GRID.AdjacentUnits(Target.CurrentCord)

	for side in range(6):
		if (Units[side] != null && Units[side].Controller != Target.Controller):

			if (Target.GetSymbol(side) == E.Symbols.SHIELD):  # Do we have a shield?
				continue

			if (Units[side].GetSymbol(side + 3) == E.Symbols.SPEAR): # Does enemy has a spear?
				return true
	return false



func KillUnit(Target) -> void:
	if (Target.Controller == E.Participant.DEFENDER):
		DefenderUnits.erase(Target)
	else:
		AttackerUnits.erase(Target)
	
	B_GRID.RemoveUnit(Target)

	if DefenderUnits.size() == 0:
		BUS.Attacker_wins += 1
		print("Attacker won" + "D:" + str(BUS.Defender_wins) + " A:" + str(BUS.Attacker_wins))
	elif AttackerUnits.size() == 0:
		BUS.Defender_wins += 1
		print("Defender won_" + "D:" + str(BUS.Defender_wins) + " A:" + str(BUS.Attacker_wins))

	
	if AttackerUnits.size() == 0 or DefenderUnits.size() == 0:
		clear_level()
		GameSetupNode.restart_level()
	


func UnitAction(Unit) -> void:
	var Units = B_GRID.AdjacentUnits(Unit.CurrentCord)

	for side in range(6):
		var UnitWeapon = Unit.GetSymbol(side)

		match UnitWeapon:
			E.Symbols.EMPTY:
				continue #####################################################################################TODO check if we could fix it
			E.Symbols.SHIELD:
				continue # We don't have a weapon

			E.Symbols.BOW:
				var Target = B_GRID.GetShotTarget(Unit.CurrentCord, side)
				if Target == null:
					continue

				if Target.Controller == Unit.Controller:
					continue

				if (Target.GetSymbol(side + 3) != E.Symbols.SHIELD): # Does Enemy has a shield?
					KillUnit(Target)
				continue
			_:
				pass
			

		if (Units[side] == null or Units[side].Controller == Unit.Controller):
			# no one to hit
			continue

		var EnemyUnit = Units[side]

		if UnitWeapon == E.Symbols.PUSH:

			# PUSH LOGIC
			var TargetTileType = B_GRID.GetDistantTileType(Unit.CurrentCord, side, 2)

			if TargetTileType == E.HexTileType.SENTINEL:  # Pushing outside the map
				# Kill
				KillUnit(EnemyUnit)
				continue


			var Target = B_GRID.GetDistantUnit(Unit.CurrentCord, side, 2)

			if Target != null: # Spot isn't empty
				KillUnit(EnemyUnit)
				continue

			B_GRID.ChangeUnitPosition(EnemyUnit, B_GRID.GetDistantCord(Unit.CurrentCord, side, 2))
			if EnemyDamage(EnemyUnit): # Simple push	
				KillUnit(EnemyUnit)
			continue
		


		# Rotation is based on where the unit is pointing toward


		if EnemyUnit.GetSymbol(side + 3) != E.Symbols.SHIELD:# Does Enemy has a shield?
			KillUnit(Units[side])
		
				



func SelectUnit(Cord : Vector2i) -> bool:
	"""
	 * Select friendly Unit on a given Cord
	 *
	 * @return true if unit has been selected in this operation
	 """

	var NewSelection : AUnit = B_GRID.GetUnit(Cord)
	if (NewSelection != null && NewSelection.Controller == current_participant):
		SelectedUnit = NewSelection
		#print("You have selected a Unit")

		return true

	return false

#endregion


#region Main Functions

func clear_level():
	current_participant = E.Participant.ATTACKER
	for unit in get_children():
		unit.queue_free()
	for tile in B_GRID.get_children():
		tile.queue_free()



func InputListener(Cord : Vector2i) -> void:
	#print(Cord)

	if SelectUnit(Cord) or SelectedUnit == null:
		return # selected a new unit or wrong input which didn't select any ally unit



	if UnitsLeftToBeSummoned > 0: # Summon phase
		"""
		* Units are placed by the players in subsequent order on their chosen "Starting Locations"
		* inside the area of the gameplay board.
		"""
		SummonUnit(Cord)
	else:  # Gameplay phase
		Gameplay(Cord)

	SelectedUnit = null  # IMPORTANT






func Gameplay(Cord : Vector2i) -> void:
	#print("Gameplay is working")

	var side = IsLegalMove(Cord) # Gets Updated with IsLegalMove()
	if side != -1: # spot is empty + we aren't hitting a shield
		# 1 Rotate

		# 2 Check for Spear

		# 3 Actions

		# 4 Move

		# 5 Check for Spear

		# 6 Actions
		MoveUnit(SelectedUnit, Cord, side)
		#print(FString::Printf(TEXT("DIRECTION_%d"), side))
		#testKillUnit(Cord)
		
		#B_GRID.ChangeUnitPosition(SelectedUnit, Cord)
		#print(FString::Printf(TEXT("_%d"), side))
		#.RotateUnit(SelectedUnit, side)

		SwitchParticipantTurn()
	


func SummonUnit(Cord : Vector2i) -> void:
	"""
	 * Summon currently selected unit to a Gameplay Board
	 *
	 *
	 * @param Cord cordinate, on which Unit will be summoned
	 """
	

	# check if unit is already summoned
	var SelectedUnitTileType = B_GRID.GetTileType(SelectedUnit.CurrentCord)

	if SelectedUnitTileType != E.HexTileType.SENTINEL:
		#print("This Unit has been already summoned")
		return
	

	var SelectedHexType = B_GRID.GetTileType(Cord)

	var bSelectedcurrent_participantSpawn = \
		(SelectedHexType == E.HexTileType.ATTACKER_SPAWN && current_participant == E.Participant.ATTACKER) or \
		(SelectedHexType == E.HexTileType.DEFENDER_SPAWN && current_participant == E.Participant.DEFENDER)

	if not bSelectedcurrent_participantSpawn:
		#print("Thats a wrong summon location")  # TODO: Don't reset SelectedUnit
		return

	#print("You summoned a Unit")

	# TeleportUnit(Cord)
	B_GRID.ChangeUnitPosition(SelectedUnit, Cord)

	if current_participant == E.Participant.ATTACKER:
		SelectedUnit.Rotate(0)
	else:
		SelectedUnit.Rotate(3)


	SwitchParticipantTurn()

	UnitsLeftToBeSummoned -= 1

#endregion

#region GameSetup


func SpawnUnits() -> void:
	"""
	* Placing Units used in combat on their "Spawn Points" near the area of the gameplay board where they are visible to the players.
	"""

	UnitsLeftToBeSummoned = AttackerUnitsTypes.size() + DefenderUnitsTypes.size()  # Flag that manages the state of the game
	
	# RESET DATA
	AttackerUnits = []
	DefenderUnits = []
	SelectedUnit = null
	
	var SpawnCord

	# spawning attacker units
	for i in range(AttackerUnitsTypes.size()):
		var newUnitScene = AttackerUnitsTypes[i]
		var new_unit = newUnitScene.instantiate()
		add_child(new_unit) # jako element sceny
		AttackerUnits.append(new_unit)

		new_unit.Controller = E.Participant.ATTACKER

		SpawnCord = B_GRID.AttackerTiles[i].TileIndex # Get spawn location
		SpawnCord += B_GRID.Directions[3]  # Move to a spot outside of the map near spawn point

		B_GRID.ChangeUnitPosition(new_unit, SpawnCord) # Adding Unit to the Gameplay Array
		

	# spawning defender units
	for i in range(DefenderUnitsTypes.size()):
		var newUnitScene = DefenderUnitsTypes[i]
		var new_unit = newUnitScene.instantiate()
		add_child(new_unit) # jako element sceny
		DefenderUnits.append(new_unit)

		new_unit.Controller = E.Participant.DEFENDER

		SpawnCord = B_GRID.DefenderTiles[i].TileIndex # Get spawn location
		SpawnCord += B_GRID.Directions[0] # Move to a spot outside of the map near spawn point

		B_GRID.ChangeUnitPosition(new_unit, SpawnCord) # Adding Unit to the Gameplay Array

	SelectedUnit = null



func SetupUnits(GameSetup, Attacker : UnitSet, Defender : UnitSet):
	GameSetupNode = GameSetup

	AttackerUnitsTypes = Attacker.Units
	DefenderUnitsTypes = Defender.Units

	SpawnUnits()
	
	
#endregion

func _physics_process(_delta):
	#func _process(_delta):
	timer += 1
	
	if Input.is_action_just_pressed("KEY_BOT_SPEED_SLOW"):
		BUS.animation_speed = BUS.animation_speed_values.NORMAL
		BUS.BotSpeed = BUS.bot_speed_values.FREEZE # 0 sec
	elif Input.is_action_just_pressed("KEY_BOT_SPEED_MEDIUM"):
		BUS.animation_speed = BUS.animation_speed_values.NORMAL
		BUS.BotSpeed = BUS.bot_speed_values.NORMAL # 0.5 sec
	elif Input.is_action_just_pressed("KEY_BOT_SPEED_FAST"):
		BUS.animation_speed = BUS.animation_speed_values.INSTANT
		
		BUS.BotSpeed = BUS.bot_speed_values.FAST # 1/60 sec
	
	# 60FPS -> timer=60 1 sec
	for i in range(1):
		if BUS.BotSpeed != 0 and timer % BUS.BotSpeed == 0:
			var actions = []
			if current_participant == E.Participant.ATTACKER and AttackerBot != null:
				timer = 0
				actions = AttackerBot.PlayMove(AttackerUnits)
			elif current_participant == E.Participant.DEFENDER and DefenderBot != null:
				timer = 0
				actions = DefenderBot.PlayMove(DefenderUnits)
			
			if actions.size() == 2:
				InputListener(actions[0])
				InputListener(actions[1])





