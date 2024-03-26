# Singleton B-GRID

extends GridManager


# Hard coding of art files is a temporary solution until a decision how to approach treating background art will be made
@onready var SentineltHexTile : PackedScene = load("res://Scenes/HexTiles/BlackHexTile.tscn")
@onready var DefaultHexTile : PackedScene = load("res://Scenes/HexTiles/StoneHexTile.tscn")
@onready var AttackerHexTile : PackedScene = load("res://Scenes/HexTiles/GrassHexTile.tscn")
@onready var DefenderHexTile : PackedScene = load("res://Scenes/HexTiles/DirtHexTile.tscn")


@onready var tile_names = \
{
	# Sentinel edge tiles
	"sentinel": load("res://Scenes/HexTiles/BlackHexTile.tscn"),

	# Normal terrain
	"grass": load("res://Scenes/HexTiles/GrassHexTile.tscn"),

	# Special terrain tiles
	"mud" : load("res://Scenes/HexTiles/DirtHexTile.tscn"),

	"hole": load("res://Scenes/HexTiles/DirtHexTile.tscn"),

	"hill": load("res://Scenes/HexTiles/DirtHexTile.tscn"),

	# Colored player summon locations
	"player-red": load("res://Scenes/HexTiles/GrassHexTile.tscn"),
	"player-blue": load("res://Scenes/HexTiles/GrassHexTile.tscn"),
	"player-purple": load("res://Scenes/HexTiles/GrassHexTile.tscn"),
	"player-teal": load("res://Scenes/HexTiles/GrassHexTile.tscn"),

}


var max_player_number : int

var summon_tiles : Array = []  # Array[Array[HexTile]] seperated by player lists all possible tiles units can be summoned to

var DefenderTiles = []

var tile_grid : Array = [] # Array[Array[HexTile]]
var unit_grid : Array = [] # Array[Array[AUnit]]

var current_spawn : String = "sentinel"

#region Tools

func change_unit_cord(unit, cord : Vector2i):

	unit_grid[unit.cord.x][unit.cord.y] = null# clean your previous location
	unit_grid[cord.x][cord.y] = unit# unit_grid Update

	unit.cord = cord# update unit Index
	
	# Move visuals of the unit
	if BM.unsummoned_units_counter > 0:
		unit.global_position = tile_grid[cord.x][cord.y].global_position
	else:
		unit.move(tile_grid[cord.x][cord.y])
	



func remove_unit(unit):

	var cord : Vector2i = unit.cord
	unit_grid[cord.x][cord.y] = null # Remove unit from gameplay grid
	unit.destroy()

#endregion


#region Coordinates tools


func get_tile_type(cord : Vector2i) -> String:
	return tile_grid[cord.x][cord.y].type

func get_unit(cord : Vector2i):
	return unit_grid[cord.x][cord.y]



func adjacent_units(start_cord : Vector2i) -> Array:
	# Returns 6 elements Array, elements can be null
	var units = []
	for side in range(6):
		var cord = GridManager.adjacent_cord(start_cord, side)
		var neighbour = unit_grid[cord.x][cord.y]
		#if (neighbour != null):
		units.append(neighbour)
	return units


func get_shot_target(start_cord : Vector2i, side : int) -> AUnit:
	while tile_grid[start_cord.x][start_cord.y].type != "sentinel":
		start_cord += DIRECTIONS[side]
		var target = unit_grid[start_cord.x][start_cord.y]
		if target != null:
			return target
	return null


func get_distant_unit(start_cord : Vector2i, side : int, distance : int) -> AUnit:
	for i in range(distance):
		start_cord += DIRECTIONS[side]
	
	return unit_grid[start_cord.x][start_cord.y]


func get_distant_tile_type(start_cord : Vector2i, side : int, distance : int) -> String:
	for i in range(distance):
		start_cord += DIRECTIONS[side]

	return tile_grid[start_cord.x][start_cord.y].type


func get_distant_cord(start_cord : Vector2i, side : int, distance : int) -> Vector2i:
	for i in range(distance):
		start_cord += DIRECTIONS[side]
	
	return start_cord


# func get_melee_targets(start_Cord : Vector2i, direction, symbol_side : int) -> Array[AUnit]:
# 	"""
# 	AI/UI tool
# 	take a side on which a weapon symbol is present -> simulate movement -> return list of damaged targets
# 	(can return friednly units)
	
# 	direction : int / Vector2i

# 	"""
# 	var units : Array[AUnit] = []
	
# 	return units

#endregion


#region Generate Grid
func is_clear() -> bool:
	return tile_grid.size() == 0 and unit_grid.size() == 0 and summon_tiles.size() == 0

func reset_data():
	summon_tiles = []
	tile_grid = []
	unit_grid = []


func init_hex_grid() -> void:
	for i in range(max_player_number):
		summon_tiles.append([])

	for i in range(grid_width):
		tile_grid.append([])
		unit_grid.append([])
		for j in range(grid_height):
			unit_grid[i].append(null)
			tile_grid[i].append(null)


func spawn_tiles() -> void:
	for y in range(grid_height):
		for x in range(grid_width):
			var oddRow = y % 2 == 0 # Sentinel Rows add aditional row
			
			var XTilePos = x * TileHorizontalOffset + y * OddRowHorizontalOffset
			var YTilePos = y * TileVerticalOffset

			var newTileScene : PackedScene = get_tile_to_spawn(x, y, oddRow)
			var newTile = newTileScene.instantiate()

			add_child(newTile)
			


			newTile.global_position.x = XTilePos
			newTile.global_position.y = YTilePos

			newTile.cord = Vector2i(x, y)
			match current_spawn:
				"sentinel":
					newTile.name = "Sentinel_HexTile"

				"default":
					newTile.name = "Default_HexTile"
			
				"player_0_spawn":
					newTile.name = "Attacker_HexTile"
					summon_tiles[0].append(newTile)

				"player_1_spawn":
					newTile.name = "Defender_HexTile"
					summon_tiles[1].append(newTile)

			newTile.type = current_spawn

			tile_grid[x][y] = newTile




func get_tile_to_spawn(x : int, y : int, bOddRow : bool) -> PackedScene:

	var TileToSpawn = SentineltHexTile # Default value for hex tile is Sentinel Tile


	current_spawn = "sentinel"

	if is_gameplay_tile(x, y, bOddRow):
		TileToSpawn = DefaultHexTile
		current_spawn = "default"

		var FirstColumnStart : int = (grid_height / 2) + border_size - (y / 2)

		if (bOddRow and x == FirstColumnStart + 1) or (not bOddRow and x == FirstColumnStart): # first column
			TileToSpawn = AttackerHexTile
			current_spawn = "player_0_spawn"
		elif (x == grid_width - border_size - 1  - (y / 2)): # last column
		
			TileToSpawn = DefenderHexTile
			current_spawn = "player_1_spawn"
			
	return TileToSpawn




#endregion
