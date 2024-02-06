extends Node

class_name GameplayManager

#region Variables

@export var AutomaticTest : E.AutomaticTestsList = E.AutomaticTestsList.EMPTY

@export var GridManager : HexGridManager



@export var AttackerUnitsTypes : Array[PackedScene]
@export var DefenderUnitsTypes : Array[PackedScene]
var AttackerUnits = []
var DefenderUnits = []

var CurrentPlayer : E.Player

var SelectedUnit

var UnitsLeftToBeSummoned

@export var AttackerBot : StateMachine
@export var DefenderBot : StateMachine

var timer = 0

func _ready():
	BUS.Tile_Selected.connect(InputListener)
	SetupGame()



#endregion






#region Tools

func SwitchPlayerTurn():
	# Currently works only for 2 players
	if CurrentPlayer == E.Player.ATTACKER:
		CurrentPlayer = E.Player.DEFENDER
	else:
		CurrentPlayer = E.Player.ATTACKER


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
	var ResultSide = GridManager.AdjacentSide(SelectedUnit.CurrentCord, Cord)  
	if ResultSide == null:
		return -1

	#print(ResultSide)
	# 2
	var EnemyUnit = GridManager.GetUnit(Cord)
	if EnemyUnit == null:  # Is there a Unit in this spot?
		return ResultSide
	
	match SelectedUnit.Symbols[0]:
		E.Symbols.INVALID:
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


	GridManager.ChangeUnitPosition(Unit, EndCord)

	if EnemyDamage(Unit):
		KillUnit(Unit)
		return
		
		
	UnitAction(SelectedUnit)


func EnemyDamage(Target : AUnit) -> bool:
	# Returns true is Enemy spear can kill the Target
	var Units = GridManager.AdjacentUnits(Target.CurrentCord)

	for side in range(6):
		if (Units[side] != null && Units[side].Controller != Target.Controller):

			if (Target.GetSymbol(side) == E.Symbols.SHIELD):  # Do we have a shield?
				continue

			if (Units[side].GetSymbol(side + 3) == E.Symbols.SPEAR): # Does enemy has a spear?
				return true
	return false



func KillUnit(Target) -> void:
	if (Target.Controller == E.Player.DEFENDER):
		DefenderUnits.erase(Target)
	else:
		AttackerUnits.erase(Target)
	
	GridManager.RemoveUnit(Target)

	if DefenderUnits.size() == 0:
		BUS.Attacker_wins += 1
		print("Attacker won" + "D:" + str(BUS.Defender_wins) + " A:" + str(BUS.Attacker_wins))
		get_tree().reload_current_scene()
	elif AttackerUnits.size() == 0:
		BUS.Defender_wins += 1
		print("Defender won_" + "D:" + str(BUS.Defender_wins) + " A:" + str(BUS.Attacker_wins))
		
		get_tree().reload_current_scene()
	


func UnitAction(Unit) -> void:
	var Units = GridManager.AdjacentUnits(Unit.CurrentCord)

	for side in range(6):
		var UnitWeapon = Unit.GetSymbol(side)

		match UnitWeapon:
			E.Symbols.INVALID:
				continue #####################################################################################TODO check if we could fix it
			E.Symbols.SHIELD:
				continue # We don't have a weapon

			E.Symbols.BOW:
				var Target = GridManager.GetShotTarget(Unit.CurrentCord, side)
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
			var TargetTileType = GridManager.GetDistantTileType(Unit.CurrentCord, side, 2)

			if TargetTileType == E.HexTileType.SENTINEL:  # Pushing outside the map
				# Kill
				KillUnit(EnemyUnit)
				continue


			var Target = GridManager.GetDistantUnit(Unit.CurrentCord, side, 2)

			if Target != null: # Spot isn't empty
				KillUnit(EnemyUnit)
				continue

			GridManager.ChangeUnitPosition(EnemyUnit, GridManager.GetDistantCord(Unit.CurrentCord, side, 2))
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

	var NewSelection : AUnit = GridManager.GetUnit(Cord)
	if (NewSelection != null && NewSelection.Controller == CurrentPlayer):
		SelectedUnit = NewSelection
		#print("You have selected a Unit")

		return true

	return false

#endregion


#region Main Functions


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
		
		#GridManager.ChangeUnitPosition(SelectedUnit, Cord)
		#print(FString::Printf(TEXT("_%d"), side))
		#.RotateUnit(SelectedUnit, side)

		SwitchPlayerTurn()
	


func SummonUnit(Cord : Vector2i) -> void:
	"""
	 * Summon currently selected unit to a Gameplay Board
	 *
	 *
	 * @param Cord cordinate, on which Unit will be summoned
	 """
	

	# check if unit is already summoned
	var SelectedUnitTileType = GridManager.GetTileType(SelectedUnit.CurrentCord)

	if SelectedUnitTileType != E.HexTileType.SENTINEL:
		#print("This Unit has been already summoned")
		return
	

	var SelectedHexType = GridManager.GetTileType(Cord)

	var bSelectedCurrentPlayerSpawn = \
		(SelectedHexType == E.HexTileType.ATTACKER_SPAWN && CurrentPlayer == E.Player.ATTACKER) or \
		(SelectedHexType == E.HexTileType.DEFENDER_SPAWN && CurrentPlayer == E.Player.DEFENDER)

	if not bSelectedCurrentPlayerSpawn:
		#print("Thats a wrong summon location")  # TODO: Don't reset SelectedUnit
		return

	#print("You summoned a Unit")

	# TeleportUnit(Cord)
	GridManager.ChangeUnitPosition(SelectedUnit, Cord)

	if CurrentPlayer == E.Player.ATTACKER:
		SelectedUnit.Rotate(0)
	else:
		SelectedUnit.Rotate(3)


	SwitchPlayerTurn()

	UnitsLeftToBeSummoned -= 1

#endregion

#region Tests






func SimpleAutomaticTests() -> void:
	if AutomaticTest == E.AutomaticTestsList.EMPTY:
		return



	if AutomaticTest == E.AutomaticTestsList.BASIC_UNIT_SETUP:
		#TODO ###############################################################################################
		# FIX, in gameplay manager setting up units if one player has already placed all of their units

		for i in range(AttackerUnits.size()):
		
			if i < AttackerUnits.size():

				InputListener(AttackerUnits[i].CurrentCord)
				InputListener(AttackerUnits[i].CurrentCord + GridManager.Directions[0])

			if i < DefenderUnits.size():

				InputListener(DefenderUnits[i].CurrentCord)
				InputListener(DefenderUnits[i].CurrentCord + GridManager.Directions[3])

		
		return

#endregion



#region GameSetup


func SpawnUnits() -> void:
	"""
	* Placing Units used in combat on their "Spawn Points" near the area of the gameplay board where they are visible to the players.
	"""

	UnitsLeftToBeSummoned = AttackerUnitsTypes.size() + DefenderUnitsTypes.size()  # Flag that manages the state of the game
	
	var SpawnCord

	# spawning attacker units
	for i in range(AttackerUnitsTypes.size()):
		var newUnitScene = AttackerUnitsTypes[i]
		var new_unit = newUnitScene.instantiate()
		add_child(new_unit) # jako element sceny
		AttackerUnits.append(new_unit)

		new_unit.Controller = E.Player.ATTACKER

		SpawnCord = GridManager.AttackerTiles[i].TileIndex # Get spawn location
		SpawnCord += HexGridManager.Directions[3]  # Move to a spot outside of the map near spawn point

		GridManager.ChangeUnitPosition(new_unit, SpawnCord) # Adding Unit to the Gameplay Array
		

	# spawning defender units
	for i in range(DefenderUnitsTypes.size()):
		var newUnitScene = DefenderUnitsTypes[i]
		var new_unit = newUnitScene.instantiate()
		add_child(new_unit) # jako element sceny
		DefenderUnits.append(new_unit)

		new_unit.Controller = E.Player.DEFENDER

		SpawnCord = GridManager.DefenderTiles[i].TileIndex # Get spawn location
		SpawnCord += HexGridManager.Directions[0] # Move to a spot outside of the map near spawn point

		GridManager.ChangeUnitPosition(new_unit, SpawnCord) # Adding Unit to the Gameplay Array

	SelectedUnit = null



func SetupGame():
	CurrentPlayer = E.Player.ATTACKER
	
	GridManager.GenerateGrid()
	SpawnUnits()

	#GetWorldTimerManager().SetTimer(TimerHandle, this, &TimerFunction, 1.0f, true, 0.5f)
	
	
	SimpleAutomaticTests()


func _physics_process(delta):
	#func _process(_delta):
	timer += 1
	
	if Input.is_action_just_pressed("KEY_BOT_SPEED_SLOW"):
		BUS.BotSpeed = 120 # 2 sec
	elif Input.is_action_just_pressed("KEY_BOT_SPEED_MEDIUM"):
		BUS.BotSpeed = 30 # 0.5 sec
	elif Input.is_action_just_pressed("KEY_BOT_SPEED_FAST"):
		BUS.BotSpeed = 1 # 1/60 sec
	
	# 60FPS -> timer=60 1 sec
	for i in range(1):
		if timer % BUS.BotSpeed == 0:
			var actions = []
			if CurrentPlayer == E.Player.ATTACKER and AttackerBot != null:
				timer = 0
				actions = AttackerBot.PlayMove(AttackerUnits)
			elif CurrentPlayer == E.Player.DEFENDER and DefenderBot != null:
				timer = 0
				actions = DefenderBot.PlayMove(DefenderUnits)
			
			if actions.size() == 2:
				InputListener(actions[0])
				InputListener(actions[1])





