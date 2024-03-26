class_name GridManager

extends Node



var map_information : GridBoard


# Hex Sprite draw gaps
const TileHorizontalOffset : float = 510.0
const TileVerticalOffset : float = 470.1
const OddRowHorizontalOffset : float = 250.0

# const TileHorizontalOffset : float = 700.0
# const TileVerticalOffset : float = 606.2
# const OddRowHorizontalOffset : float = 350.0


var grid_width : int
var	grid_height : int


"""
Thickness of a Sentinel perimiter around the gameplay area.

If size is even it shifts the map. (used by simple map shift system from map_data resource)
May be increased to allow for ease of development
"""
var border_size : int = 1   



static var DIRECTIONS = [ \
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0),
	Vector2i(0, -1),
	Vector2i(1, -1)]


#region Coordinate Tools

static func is_adjacent(Cord1 : Vector2i, Cord2 : Vector2i) -> bool:
	return (Cord2 - Cord1) in DIRECTIONS

static func adjacent_side(Cord1 : Vector2i, Cord2 : Vector2i) -> int:
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
	pass


func adjust_grid_size() -> void:
	# sentinels appear on both sides
	grid_width += (border_size * 2)
	grid_height += (border_size * 2)
	#grid_width += (grid_height / 2) # adjustment for Axial grid system


func init_hex_grid() -> void:
	pass

func spawn_tiles() -> void:
	pass


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

	init_hex_grid()
	spawn_tiles()

#endregion
