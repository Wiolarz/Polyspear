# Singleton - W_GRID

extends Node


const TileHorizontalOffset : float = 700.0
const TileVerticalOffset : float = 606.2
const OddRowHorizontalOffset : float = 350.0


#var map_data : MapData  # currently no need to store this info duo to simple nature of this resource

# Hard coding of art files is a temporary solution until a decision how to approach treating background art will be made
@onready var SentineltHexTile : PackedScene = load("res://Scenes/HexTiles/BlackHexTile.tscn")
@onready var WallHexTile : PackedScene = load("res://Scenes/HexTiles/StoneHexTile.tscn")
@onready var DefaultHexTile : PackedScene = load("res://Scenes/HexTiles/GrassHexTile.tscn")




var GridWidth : int = 5
var	GridHeight : int = 5

"""
Thickness of a Sentinel perimiter around the gameplay area.

If size is even it shifts the map. (used by simple map shift system from map_data resource)
May be increased to allow for ease of development
"""
var BorderSize : int = 1   



var hex_grid = []  # [[Place]]
var hero_grid = [] # [[Hero]]


var current_spawn : E.WorldMapTiles = E.WorldMapTiles.SENTINEL

static var DIRECTIONS = [ \
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0),
	Vector2i(0, -1),
	Vector2i(1, -1)]



func change_hero_position(hero, cord : Vector2i):

	hero_grid[hero.cord.x][hero.cord.y] = null# clean your previous location
	hero_grid[cord.x][cord.y] = hero

	hero.cord = cord
	
	# Move visuals of the unit
	hero.move(hero_grid[cord.x][cord.y])
	



func remove_hero(hero):

	var cord : Vector2i = hero.cord
	hero_grid[cord.x][cord.y] = null # Remove unit from gameplay grid

	hero.destroy()

#region Coordinates tools


func is_moveable(cord : Vector2i):
	if hex_grid[cord.x][cord.y].type in \
		[E.WorldMapTiles.EMPTY, E.WorldMapTiles.CITY,  E.WorldMapTiles.PLACE]:
			return true
	
	return false

func get_tile_controller(cord : Vector2i):
	var hero = get_hero(cord)
	if hero != null:
		return hero.controller
	return hex_grid[cord.x][cord.y].controller


func get_army(cord : Vector2i):
	var hero = get_hero(cord)
	if hero != null:
		return hero.army
	return hex_grid[cord.x][cord.y].defender_units


func get_city(cord : Vector2i) -> City:
	var city = hex_grid[cord.x][cord.y]
	if city is City:
		return city
	return null

func get_hero(cord : Vector2i):
	return hero_grid[cord.x][cord.y]



func is_adjacent(Cord1 : Vector2i, Cord2 : Vector2i) -> bool:
	return (Cord2 - Cord1) in DIRECTIONS

func AdjacentSide(Cord1 : Vector2i, Cord2 : Vector2i) -> int:
	"""
	Return shared side between Cord1 and Cord2, if the Cords are adjacent

	@param Cord1 
	@param Cord2 
	@return int32 Side
	@note -1 is return, when Cord1 and Cord2 don't have shared side
	"""
	if (Cord2 - Cord1) in DIRECTIONS:
		return DIRECTIONS.find(Cord2 - Cord1)
	return -1


func AdjacentCord(BaseCord : Vector2i, Side : int) -> Vector2i:
	"""
    Return cord adjacent to BaseCord at given Side
    
    @param BaseCord
    @param Side {0, 1, ..., 5}
    @return Vector2i cord adjacent to BaseCord
    """
	return BaseCord + DIRECTIONS[Side]


#endregion


#region GenerateGrid
func AdjustGridSize() -> void:
	# sentinels appear on both sides
	GridWidth += (BorderSize * 2)
	GridHeight += (BorderSize * 2)
	GridWidth += (GridHeight / 2) # adjustment for Axial grid system



func InitHexGridArray() -> void:
	for i in range(GridWidth):
		hex_grid.append([])
		hero_grid.append([])
		for j in range(GridHeight):
			hero_grid[i].append(null)
			hex_grid[i].append(null)


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

			newTile.cord = Vector2i(x, y)
			match current_spawn:
				E.WorldMapTiles.SENTINEL:
					newTile.name = "Sentinel_HexTile"

				E.WorldMapTiles.EMPTY:
					newTile.name = "Empty_HexTile"
			
				E.WorldMapTiles.WALL:
					newTile.name = "Wall_HexTile"


			newTile.tile_type = current_spawn

			hex_grid[x][y] = newTile


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


	current_spawn = E.WorldMapTiles.SENTINEL

	if isGameplayTile(x, y, bOddRow):
		TileToSpawn = DefaultHexTile
		current_spawn = E.WorldMapTiles.EMPTY

		var FirstColumnStart : int = (GridHeight / 2) + BorderSize - (y / 2)

		if (bOddRow and x == FirstColumnStart + 1) or (not bOddRow and x == FirstColumnStart): # first column
			TileToSpawn = WallHexTile
			current_spawn = E.WorldMapTiles.WALL
		elif (x == GridWidth - BorderSize - 1  - (y / 2)): # last column
			TileToSpawn = WallHexTile
			current_spawn = E.WorldMapTiles.WALL
			
	return TileToSpawn


func ResetData():
	hex_grid = []
	hero_grid = []

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
