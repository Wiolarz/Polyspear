class_name GenericHexGrid
extends RefCounted #default

## used to specify direction on a hex grid
enum GridDirections
{
	LEFT,
	TOP_LEFT,
	TOP_RIGHT,
	RIGHT,
	BOTTOM_RIGHT,
	BOTTOM_LEFT,
}

const DIRECTION_FRONT = GridDirections.LEFT
const TILES_NOT_ADJACENT = -1

## see E.GridDirections
const DIRECTION_TO_OFFSET = [ \
	Vector2i(-1, 0),
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 1),
]

var width : int
var	height : int
var hexes : Array = [] # Array[Array[HexType]]
var sentinel

func _init(new_width:int, new_height:int, new_sentinel):
	width = new_width
	height = new_height
	sentinel = new_sentinel

	hexes.resize(width)
	for x in range(width):
		hexes[x] = []
		hexes[x].resize(height)


func is_on_grid(coord : Vector2i) -> bool:
	return coord.x >= 0 and coord.y >= 0 \
		and coord.x < width and coord.y < height


func get_hex(coord : Vector2i):
	if not is_on_grid(coord):
		return sentinel
	var hex = hexes[coord.x][coord.y]
	if not hex:
		return sentinel
	return hex


func set_hex(coord : Vector2i, value):
	assert(is_on_grid(coord), "set_hex not on a grid "+str(coord))
	hexes[coord.x][coord.y] = value


static func direction_to_name(d : GridDirections) -> String:
	return GridDirections.keys()[d]


static func rotate_clockwise(direction : GridDirections, sides : int) -> GridDirections:
	return (direction + sides) % 6 as GridDirections


static func opposite_direction(direction : GridDirections) -> GridDirections:
	return rotate_clockwise(direction, 3)


static func is_adjacent(coord1 : Vector2i, coord2 : Vector2i) -> bool:
	return direction_to_adjacent(coord1, coord2) != TILES_NOT_ADJACENT


## Direction from coord1 to coord2 if adjacent
## Or TILES_NOT_ADJACENT if not adjacent
static func direction_to_adjacent(coord1 : Vector2i, coord2 : Vector2i) -> int:
	return DIRECTION_TO_OFFSET.find(coord2 - coord1)


static func adjacent_coord(coord : Vector2i, side : int) -> Vector2i:
	return coord + DIRECTION_TO_OFFSET[side]


static func adjacent_coord_distant(coord : Vector2i, side : int, distance:int) -> Vector2i:
	return coord + distance * DIRECTION_TO_OFFSET[side]
