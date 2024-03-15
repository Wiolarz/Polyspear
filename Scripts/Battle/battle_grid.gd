# Singleton B-GRID

extends GridManager


# Hard coding of art files is a temporary solution until a decision how to approach treating background art will be made
@onready var SentineltHexTile : PackedScene = load("res://Scenes/HexTiles/BlackHexTile.tscn")
@onready var DefaultHexTile : PackedScene = load("res://Scenes/HexTiles/StoneHexTile.tscn")
@onready var AttackerHexTile : PackedScene = load("res://Scenes/HexTiles/GrassHexTile.tscn")
@onready var DefenderHexTile : PackedScene = load("res://Scenes/HexTiles/DirtHexTile.tscn")


var AttackerTiles = []
var DefenderTiles = []

var HexGrid : Array = [] # Array[Array[HexTile]]
var UnitGrid : Array = [] # Array[Array[AUnit]]

var current_spawn : E.HexTileType = E.HexTileType.SENTINEL

#region Tools

func ChangeUnitPosition(Unit, Cord : Vector2i):

	UnitGrid[Unit.cord.x][Unit.cord.y] = null# clean your previous location
	UnitGrid[Cord.x][Cord.y] = Unit# UnitGrid Update

	Unit.cord = Cord# update Unit Index
	
	# Move visuals of the unit
	if BM.UnitsLeftToBeSummoned > 0:
		Unit.global_position = HexGrid[Cord.x][Cord.y].global_position
	else:
		Unit.move(HexGrid[Cord.x][Cord.y])
	



func RemoveUnit(Unit):

	var Cord : Vector2i = Unit.cord
	UnitGrid[Cord.x][Cord.y] = null # Remove unit from gameplay grid

	#Unit.SetActorLocation(HexGrid[0][0].GetActorLocation())
	Unit.destroy()

#endregion


#region Coordinates tools


func get_tile_type(Cord : Vector2i) -> E.HexTileType:
	return HexGrid[Cord.x][Cord.y].tile_type

func get_unit(Cord : Vector2i):
	return UnitGrid[Cord.x][Cord.y]



func AdjacentUnits(BaseCord : Vector2i):
	# Returns 6 elements Array, elements can be null
	var Units = []
	for side in range(6):
		var Cord = adjacent_cord(BaseCord, side)
		var Neighbour = UnitGrid[Cord.x][Cord.y]
		#if (Neighbour != null)
		Units.append(Neighbour)
	return Units


func GetShotTarget(StartCord : Vector2i, Side : int):
	while HexGrid[StartCord.x][StartCord.y].tile_type != E.HexTileType.SENTINEL:
		StartCord += DIRECTIONS[Side]
		var Target = UnitGrid[StartCord.x][StartCord.y]
		if Target != null:
			return Target
	return null


func GetDistantUnit(StartCord : Vector2i, Side : int, Distance : int) -> AUnit:
	for i in range(Distance):
		StartCord += DIRECTIONS[Side]
	
	return UnitGrid[StartCord.x][StartCord.y]


func GetDistantTileType(StartCord : Vector2i, Side : int, Distance : int) -> E.HexTileType:
	for i in range(Distance):
		StartCord += DIRECTIONS[Side]

	return HexGrid[StartCord.x][StartCord.y].tile_type


func  GetDistantCord(StartCord : Vector2i, Side : int, Distance : int) -> Vector2i:
	var NewCord = StartCord
	for i in range(Distance):
		NewCord += DIRECTIONS[Side]
	
	return NewCord



func get_melee_targets(StartCord : Vector2i, direction, SymbolSide : int) -> Array[AUnit]:
	"""TODO
	
	direction : int / Vector2i

	"""
	var Units : Array[AUnit] = []
	
	return Units

#endregion


#region Generate Grid

func init_hex_grid() -> void:
	for i in range(grid_width):
		HexGrid.append([])
		UnitGrid.append([])
		for j in range(grid_height):
			UnitGrid[i].append(null)
			HexGrid[i].append(null)


func spawn_tiles() -> void:
	for y in range(grid_height):
		for x in range(grid_width):
			var oddRow = y % 2 == 0 # Sentinel Rows add aditional row
			
			var XTilePos = x * TileHorizontalOffset + y * OddRowHorizontalOffset
			var YTilePos = y * TileVerticalOffset

			var newTileScene : PackedScene = GetTileToSpawn(x, y, oddRow)
			var newTile = newTileScene.instantiate()

			add_child(newTile)
			


			newTile.global_position.x = XTilePos
			newTile.global_position.y = YTilePos

			newTile.cord = Vector2i(x, y)
			match current_spawn:
				E.HexTileType.SENTINEL:
					newTile.name = "Sentinel_HexTile"

				E.HexTileType.DEFAULT:
					newTile.name = "Default_HexTile"
			
				E.HexTileType.ATTACKER_SPAWN:
					newTile.name = "Attacker_HexTile"
					AttackerTiles.append(newTile)

				E.HexTileType.DEFENDER_SPAWN:
					newTile.name = "Defender_HexTile"
					DefenderTiles.append(newTile)

			newTile.tile_type = current_spawn

			HexGrid[x][y] = newTile




func GetTileToSpawn(x : int, y : int, bOddRow : bool) -> PackedScene:

	var TileToSpawn = SentineltHexTile # Default value for hex tile is Sentinel Tile


	current_spawn = E.HexTileType.SENTINEL

	if is_gameplay_tile(x, y, bOddRow):
		TileToSpawn = DefaultHexTile
		current_spawn = E.HexTileType.DEFAULT

		var FirstColumnStart : int = (grid_height / 2) + border_size - (y / 2)

		if (bOddRow and x == FirstColumnStart + 1) or (not bOddRow and x == FirstColumnStart): # first column
			TileToSpawn = AttackerHexTile
			current_spawn = E.HexTileType.ATTACKER_SPAWN
		elif (x == grid_width - border_size - 1  - (y / 2)): # last column
		
			TileToSpawn = DefenderHexTile
			current_spawn = E.HexTileType.DEFENDER_SPAWN
			
	return TileToSpawn


func reset_data():
	AttackerTiles = []
	DefenderTiles = []
	HexGrid = []
	UnitGrid = []

#endregion
