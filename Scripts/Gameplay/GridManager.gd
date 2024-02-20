class_name HexGridManager

extends Node


const TileHorizontalOffset : float = 700.0
const TileVerticalOffset : float = 606.2
const OddRowHorizontalOffset : float = 350.0


#var map_data : MapData  # currently no need to store this info duo to simple nature of this resource

# Hard coding of art files is a temporary solution until a decision how to approach treating background art will be made
@onready var SentineltHexTile : PackedScene = load("res://Scenes/HexTiles/BlackHexTile.tscn")
@onready var DefaultHexTile : PackedScene = load("res://Scenes/HexTiles/StoneHexTile.tscn")
@onready var AttackerHexTile : PackedScene = load("res://Scenes/HexTiles/GrassHexTile.tscn")
@onready var DefenderHexTile : PackedScene = load("res://Scenes/HexTiles/DirtHexTile.tscn")


var GridWidth : int = 5
var	GridHeight : int = 5




"""
Thickness of a Sentinel perimiter around the gameplay area.

If size is even it shifts the map. (used by simple map shift system from map_data resource)
May be increased to allow for ease of development
"""
var BorderSize : int = 1   




var AttackerTiles = []
var DefenderTiles = []

var HexGrid = []
var UnitGrid = []

var current_spawn : E.HexTileType = E.HexTileType.SENTINEL

static var Directions = [ \
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0),
	Vector2i(0, -1),
	Vector2i(1, -1)]



func GetTileType(Cord : Vector2i) -> E.HexTileType:
	return HexGrid[Cord.x][Cord.y].TileType

func GetUnit(Cord : Vector2i):
	return UnitGrid[Cord.x][Cord.y]

func ChangeUnitPosition(Unit, Cord : Vector2i):

	UnitGrid[Unit.CurrentCord.x][Unit.CurrentCord.y] = null# clean your previous location
	UnitGrid[Cord.x][Cord.y] = Unit# UnitGrid Update

	Unit.CurrentCord = Cord# update Unit Index
	
	# Move visuals of the unit
	if GM.UnitsLeftToBeSummoned > 0:
		Unit.global_position = HexGrid[Cord.x][Cord.y].global_position
	else:
		Unit.Move(HexGrid[Cord.x][Cord.y])
	



func RemoveUnit(Unit):

	var Cord : Vector2i = Unit.CurrentCord
	UnitGrid[Cord.x][Cord.y] = null # Remove unit from gameplay grid

	#Unit.SetActorLocation(HexGrid[0][0].GetActorLocation())
	Unit.Destroy()

#region Coordinates tools

func AdjacentUnits(BaseCord : Vector2i):
	# Returns 6 elements Array, elements can be null
	var Units = []
	for side in range(6):
		var Cord = AdjacentCord(BaseCord, side)
		var Neighbour = UnitGrid[Cord.x][Cord.y]
		#if (Neighbour != null)
		Units.append(Neighbour)
	return Units


func GetShotTarget(StartCord : Vector2i, Side : int):
	while HexGrid[StartCord.x][StartCord.y].TileType != E.HexTileType.SENTINEL:
		StartCord += Directions[Side]
		var Target = UnitGrid[StartCord.x][StartCord.y]
		if Target != null:
			return Target
	return null


func GetDistantUnit(StartCord : Vector2i, Side : int, Distance : int) -> AUnit:
	for i in range(Distance):
		StartCord += Directions[Side]
	
	return UnitGrid[StartCord.x][StartCord.y]


func GetDistantTileType(StartCord : Vector2i, Side : int, Distance : int) -> E.HexTileType:
	for i in range(Distance):
		StartCord += Directions[Side]

	return HexGrid[StartCord.x][StartCord.y].TileType


func  GetDistantCord(StartCord : Vector2i, Side : int, Distance : int) -> Vector2i:
	var NewCord = StartCord
	for i in range(Distance):
		NewCord += Directions[Side]
	
	return NewCord



func GetMeleeDamageTargets(StartCord : Vector2i, direction, SymbolSide : int) -> Array[AUnit]:
	"""TODO
	
	direction : int / Vector2i

	"""
	var Units : Array[AUnit] = []
	
	return Units


func IsAdjacent(Cord1 : Vector2i, Cord2 : Vector2i) -> bool:
	return (Cord2 - Cord1) in Directions

func AdjacentSide(Cord1 : Vector2i, Cord2 : Vector2i) -> int:
	"""
	Return shared side between Cord1 and Cord2, if the Cords are adjacent

	@param Cord1 
	@param Cord2 
	@return int32 Side
	@note -1 is return, when Cord1 and Cord2 don't have shared side
	"""
	if (Cord2 - Cord1) in Directions:
		return Directions.find(Cord2 - Cord1)
	return -1


func AdjacentCord(BaseCord : Vector2i, Side : int) -> Vector2i:
	"""
	  Return cord adjacent to BaseCord at given Side
	 
	  @param BaseCord
	  @param Side {0, 1, ..., 5}
	  @return Vector2i Cord adjacent to BaseCord
	  """
	return BaseCord + Directions[Side]

"""
/ Maybe TODO
Vector2i AdjacentCord(Vector2i BaseCord, Vector2i Direction)
{
	/
	  Return cord adjacent to BaseCord at given Direction
	 
	  @param BaseCord
	  @param Side {0, 1, ..., 5}
	  @return Vector2i Cord adjacent to BaseCord
	 /
	# TODO: Normalize dircetion first to match one of the Directions
	#return BaseCord + Directions[Side]
#}
"""
#endregion

#region GenerateGrid


#func BlueprintsCheck() -> void
#{
	#checkf(AttackerHexTile != NULL, TEXT("no AttackerHexTile"))
	#checkf(DefaultHexTile != NULL, TEXT("no DefaultHexTile"))
	#checkf(DefenderHexTile != NULL, TEXT("no DefenderHexTile"))
	#checkf(SentinelHexTile != NULL, TEXT("no SentinelHexTile"))	
#}


func AdjustGridSize() -> void:
	# sentinels appear on both sides
	GridWidth += (BorderSize * 2)
	GridHeight += (BorderSize * 2)
	GridWidth += (GridHeight / 2) # adjustment for Axial grid system


##include <typeinfo>

func InitHexGridArray() -> void:
	for i in range(GridWidth):
		HexGrid.append([])
		UnitGrid.append([])
		for j in range(GridHeight):
			UnitGrid[i].append(null)
			HexGrid[i].append(null)


func SpawnTiles() -> void:
	for y in range(GridHeight):
		for x in range(GridWidth):
			var oddRow = y % 2 == 0 # Sentinel Rows add aditional row
			
			var XTilePos = x * TileHorizontalOffset + y * OddRowHorizontalOffset
			var YTilePos = y * TileVerticalOffset

			var newTileScene : PackedScene = GetTileToSpawn(x, y, oddRow)
			var newTile = newTileScene.instantiate()

			add_child(newTile)
			


			newTile.global_position.x = XTilePos
			newTile.global_position.y = YTilePos

			newTile.TileIndex = Vector2i(x, y)
			
			if current_spawn == E.HexTileType.SENTINEL:
				pass#newTile.SetActorLabel(FString::Printf(TEXT("Tile_Sentinel_%d-%d"), x, y))

			elif current_spawn == E.HexTileType.DEFAULT:
				pass#newTile.SetActorLabel(FString::Printf(TEXT("Tile_Default_%d-%d"), x, y))
			
			elif current_spawn == E.HexTileType.ATTACKER_SPAWN:
				pass#newTile.SetActorLabel(FString::Printf(TEXT("Tile_Attacker_Spawn_%d-%d"), x, y))
				AttackerTiles.append(newTile)

			elif current_spawn == E.HexTileType.DEFENDER_SPAWN:
				pass#newTile.SetActorLabel(FString::Printf(TEXT("Tile_Defender_Spawn_%d-%d"), x, y))
				DefenderTiles.append(newTile)

			newTile.TileType = current_spawn

			HexGrid[x][y] = newTile


func isGameplayTile(x : int, y : int, bOddRow : bool) -> bool:
	"""
	3:1 - 7:1 even 5
	3:2 - 6:2 odd 4
	2:3 - 6:3 even 5
	2:4 - 5:4 odd 4
	1:5 - 6:5 even 5

	"""

	var start : int = floor(GridHeight / 2)# axial start position
	var gameplay_width_start = start + BorderSize - floor(y / 2)
	var gameplay_height_start = BorderSize

	var gameplay_height_end = GridHeight - BorderSize
	var gameplay_width_odd_end = GridWidth - BorderSize - floor(y / 2)
	var gameplay_width_even_end = GridWidth - BorderSize - floor(y / 2)
	################################################################################################################################### clean
	# Height
	# even row width
	var bHeight = gameplay_height_start <= y and y < gameplay_height_end
	var bEven_Row_Width = gameplay_width_start	 <= x and x < gameplay_width_even_end and not bOddRow
	var bOdd_Row_Width = gameplay_width_start + 1 <= x and x < gameplay_width_odd_end and bOddRow
	return bHeight and (bEven_Row_Width or bOdd_Row_Width)


func GetTileToSpawn(x : int, y : int, bOddRow : bool) -> PackedScene:

	var TileToSpawn = SentineltHexTile # Default value for hex tile is Sentinel Tile


	current_spawn = E.HexTileType.SENTINEL

	if isGameplayTile(x, y, bOddRow):
		TileToSpawn = DefaultHexTile
		current_spawn = E.HexTileType.DEFAULT

		var FirstColumnStart : int = (GridHeight / 2) + BorderSize - (y / 2)

		if (bOddRow and x == FirstColumnStart + 1) or (not bOddRow and x == FirstColumnStart): # first column
			TileToSpawn = AttackerHexTile
			current_spawn = E.HexTileType.ATTACKER_SPAWN
		elif (x == GridWidth - BorderSize - 1  - (y / 2)): # last column
		
			TileToSpawn = DefenderHexTile
			current_spawn = E.HexTileType.DEFENDER_SPAWN
			
	return TileToSpawn


func ResetData():
	AttackerTiles = []
	DefenderTiles = []
	HexGrid = []
	UnitGrid = []

func GenerateGrid(new_map_data : MapData = null) -> void:
	ResetData()
	
	if new_map_data != null:
		GridWidth = new_map_data.GridWidth
		GridHeight = new_map_data.GridHeight
		match new_map_data.map_shape:
			E.MapShape.CLASSIC:
				if BorderSize % 2 == 0:
					BorderSize += 1
			E.MapShape.SHIFTED:
				if BorderSize % 2 != 0:
					BorderSize += 1
				

	# "+2" is to reserve space for sentinel tiles on each side of the board
	AdjustGridSize()

	InitHexGridArray()
	SpawnTiles()



#endregion
