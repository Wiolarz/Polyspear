class_name GridManager
extends Node


var map_information : GridBoard

# const Basic scene to get Collision area for player input
@onready var BASIC_HEX_TILE : PackedScene = load("res://Scenes/Form/TileForm.tscn")


# Hex Sprite draw gaps
const visual_empty_border = 11.0
const TileHorizontalOffset : float = 529.0 + visual_empty_border # current sprite size 529
const TileVerticalOffset : float = (608 + visual_empty_border) * 0.75
const OddRowHorizontalOffset : float = TileHorizontalOffset / 2

# const TileHorizontalOffset : float = 700.0
# const TileVerticalOffset : float = 606.2
# const OddRowHorizontalOffset : float = 350.0


var grid_width : int
var	grid_height : int

const border_size : int = 1  # Thickness of a Sentinel perimiter around the gameplay area.


static var DIRECTIONS = [ \
	Vector2i(-1, 0),
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 1),
]



var tile_grid : Array = []  # Array[Array[Place]]
var unit_grid : Array = [] # Array[Array[AUnit/Army]]

#region Coordinate Tools

static func is_adjacent(Cord1 : Vector2i, Cord2 : Vector2i) -> bool:
	return (Cord2 - Cord1) in DIRECTIONS

static func adjacent_side(Cord1 : Vector2i, Cord2 : Vector2i) -> int:
	"""
	Return shared side between Cord1 and Cord2, if the Cords are adjacent
	Side from Coord1 perspective
	@param Cord1 
	@param Cord2 
	@return int32 Side
	@note -1 is return, when Cord1 and Cord2 don't have shared side
	"""
	if (Cord2 - Cord1) in DIRECTIONS:
		return DIRECTIONS.find(Cord2 - Cord1)
	return -1


static func adjacent_cord(BaseCord : Vector2i, Side : int) -> Vector2i:
	"""
	Return cord adjacent to BaseCord at given Side
	
	@param BaseCord
	@param Side {0, 1, ..., 5}
	@return Vector2i cord adjacent to BaseCord
	"""
	return BaseCord + DIRECTIONS[Side]


#endregion

#region Generate Grid

func reset_data() -> void:
	# Remove the content of map from memory
	tile_grid = []
	unit_grid = []
	map_information = null

	for tile in get_children():
		tile.queue_free()


func adjust_grid_size() -> void:
	# sentinels appear on both sides
	grid_width += (border_size * 2)
	grid_height += (border_size * 2)
	#grid_width += (grid_height / 2) # adjustment for Axial grid system


func init_tile_grid() -> void:
	for i in range(grid_width):
		tile_grid.append([])
		unit_grid.append([])
		for j in range(grid_height):
			unit_grid[i].append(null)
			tile_grid[i].append(null)


func spawn_tiles() -> void:
	var grid = map_information.grid_data

	for x in range(grid_width):
		for y in range(grid_height):
			# creating a node
			var new_tile_scene : PackedScene = BASIC_HEX_TILE
			var new_tile : HexTile = new_tile_scene.instantiate()
			add_child(new_tile)
			
			# Set tile cord
			tile_grid[x][y] = new_tile
			new_tile.cord = Vector2i(x, y)
			
			# setting a new tile node visual location
			var x_tile_pos = x * TileHorizontalOffset + y * OddRowHorizontalOffset
			var y_tile_pos = y * TileVerticalOffset
			new_tile.global_position.x = x_tile_pos
			new_tile.global_position.y = y_tile_pos
			
			# apllying sentinel border correction to data files cords
			var data_x = x - border_size
			var data_y = y - border_size
			if data_x >= 0 and data_y >= 0 and data_x < grid.size() and data_y < grid[0].size(): 
				grid[data_x][data_y].apply_data(new_tile)  # texture + game logic applied

			# Debug information

			new_tile.name = new_tile.type + "_HexTile_" + str(new_tile.cord)



func is_gameplay_tile(x : int, y : int, bOddRow : bool) -> bool:
	"""
	3:1 - 7:1 even 5
	3:2 - 6:2 odd 4
	2:3 - 6:3 even 5
	2:4 - 5:4 odd 4
	1:5 - 6:5 even 5

	"""

	var start : int = floor(grid_height / 2) # axial start position
	var gameplay_width_start = start + border_size - floor(y / 2)
	var gameplay_height_start = border_size

	var gameplay_height_end = grid_height - border_size
	var gameplay_width_odd_end = grid_width - border_size - floor(y / 2)
	var gameplay_width_even_end = grid_width - border_size - floor(y / 2)
	################################################################################################################################### clean
	# Height
	# even row width
	var bHeight = gameplay_height_start <= y and y < gameplay_height_end
	var bEven_Row_Width = gameplay_width_start	 <= x and x < gameplay_width_even_end and not bOddRow
	var bOdd_Row_Width = gameplay_width_start + 1 <= x and x < gameplay_width_odd_end and bOddRow
	return bHeight and (bEven_Row_Width or bOdd_Row_Width)


func is_clear() -> bool:
	return true

func generate_grid(new_map_data : GridBoard) -> void:
	"""
	Main grid map generation function
	"""
	assert(is_clear(), "Grid is already loaded")
	reset_data()
	
	new_map_data.apply_data()
	

	# "+2" is to reserve space for sentinel tiles on each side of the board
	adjust_grid_size()

	init_tile_grid()
	spawn_tiles()

	

#endregion
