class_name GridManager
extends Node2D


# Hex Sprite draw gaps
const VISUAL_EMPTY_BORDER = 11.0
const TILE_OFFSET_HORIZONTAL_PER_X : float = 529.0 + VISUAL_EMPTY_BORDER # current sprite size 529
const TILE_OFFSET_HORIZONTAL_PER_Y : float = TILE_OFFSET_HORIZONTAL_PER_X / 2
const TILE_OFFSET_VERTICAL_PER_Y : float = (608 + VISUAL_EMPTY_BORDER) * 0.75
## Thickness of a Sentinel perimeter around the gameplay area.
const SENTINEL_BORDER_SIZE : int = 1

## see E.GridDirections
const DIRECTIONS = [ \
	Vector2i(-1, 0),
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 1),
]

const TILES_NOT_ADJACENT = -1

@export var map_information : DataGenericMap

@export var grid_width : int
@export var	grid_height : int

@export var tile_grid : Array = []  # Array[Array[TileForm]]
@export var unit_grid : Array = [] # Array[Array[UnitForm/ArmyForm]]

#region Coordinate Tools

static func is_adjacent(coord1 : Vector2i, coord2 : Vector2i) -> bool:
	return adjacent_side_direction(coord1, coord2) != TILES_NOT_ADJACENT


## If the coords are adjacent, returns direction to coord2
## from Coord1 perspective
## @param coord1
## @param coord2
## @return int32 side
## @note TILES_NOT_ADJACENT (-1) is returned,
## when coord1 and coord2 don't have shared side
static func adjacent_side_direction(coord1 : Vector2i, coord2 : Vector2i) -> int:
	return DIRECTIONS.find(coord2 - coord1)

static func adjacent_coord(base_coord : Vector2i, side : int) -> Vector2i:
	"""
	Return coord adjacent to Base coord at given side

	@param base_coord
	@param side {0, 1, ..., 5}
	@return Vector2i coord adjacent to base_coord
	"""
	return base_coord + DIRECTIONS[side]


func is_on_grid(coord : Vector2i):
	return coord.x >= 0 and coord.y >= 0 \
		and coord.x < grid_width and coord.y < grid_height


func get_tile(coord : Vector2i) -> TileForm:
	return tile_grid[coord.x][coord.y]


func get_all_field_coords() -> Array[Vector2i]:
	var result : Array[Vector2i] = []
	for x in range(grid_width):
		for y in range(grid_height):
			result.append(Vector2i(x,y))
	return result


func get_tile_type(coord : Vector2i) -> String:
	return tile_grid[coord.x][coord.y].type


func get_unit(coord : Vector2i):
	return unit_grid[coord.x][coord.y]


func get_distant_unit(start_coord : Vector2i, side : int, distance : int):
	var target_coord = start_coord + distance * DIRECTIONS[side]
	if not is_on_grid(target_coord):
		return null
	return get_unit(target_coord)


## Returns 6 elements Array, elements can be null
func adjacent_units(start_coord : Vector2i) -> Array:
	var units = []
	for side in range(6):
		var coord = GridManager.adjacent_coord(start_coord, side)
		var neighbor = get_unit(coord)
		units.append(neighbor)
	return units


func get_distant_tile_type(start_coord : Vector2i, side : int, distance : int) -> String:
	for i in range(distance):
		start_coord += DIRECTIONS[side]

	return tile_grid[start_coord.x][start_coord.y].type


func get_distant_coord(start_coord : Vector2i, side : int, distance : int) -> Vector2i:
	for i in range(distance):
		start_coord += DIRECTIONS[side]

	return start_coord

func get_bounds_global_position() -> Rect2:
	if tile_grid.size() == 0 or tile_grid[0].size() == 0:
		push_warning("asking not initialized grid for camera bounding box")
		return Rect2(0, 0, 0, 0)
	var top_left = get_tile(Vector2i(0,0)).global_position
	var bottom_right = get_tile(Vector2i(grid_width-1,grid_height-1)).global_position
	return Rect2(top_left, bottom_right - top_left)
#endregion

#region Generate Grid

## Remove the content of map from memory
func reset_data() -> void:
	tile_grid = []
	unit_grid = []
	map_information = null

	for tile in get_children():
		tile.queue_free()


func init_tile_grid() -> void:
	for i in range(grid_width):
		tile_grid.append([])
		unit_grid.append([])
		for j in range(grid_height):
			unit_grid[i].append(null)
			tile_grid[i].append(null)


func spawn_tiles() -> void:
	for x in range(grid_width):
		for y in range(grid_height):
			spawn_tile(x, y)


static func coord_to_global_position(coord : Vector2i) -> Vector2:
	var result = Vector2()
	# note: x is direction right, y is direction bottom_right
	result.x =  coord.x * TILE_OFFSET_HORIZONTAL_PER_X \
			+ coord.y * TILE_OFFSET_HORIZONTAL_PER_Y
	result.y =  coord.y * TILE_OFFSET_VERTICAL_PER_Y
	return result

## x,y are coords on the grid
func spawn_tile(x : int, y : int) -> TileForm:
	# creating a node
	var coord = Vector2i(x, y)
	var new_tile : TileForm = CFG.HEX_TILE_FORM_SCENE.instantiate()
	add_child(new_tile)

	# Set tile coord
	tile_grid[x][y] = new_tile
	new_tile.set_coord(coord)
	# setting a new tile node visual location
	new_tile.position = GridManager.coord_to_global_position(coord)

	# applying sentinel border correction to data files coords
	var data_x = x - SENTINEL_BORDER_SIZE
	var data_y = y - SENTINEL_BORDER_SIZE
	if map_information.is_on_grid(Vector2i(data_x, data_y)):
		# apply texture + game logic
		map_information.grid_data[data_x][data_y].apply_data(new_tile)

	# Debug information
	new_tile.name = new_tile.type + "_TileForm_" + str(new_tile.coord)
	on_tile_spawned(new_tile)
	return new_tile

func on_tile_spawned(_tile: TileForm) -> void:
	pass

func generate_special_tiles() -> void:
	pass


func is_clear() -> bool:
	return true


func generate_grid(new_map_data : DataGenericMap) -> void:
	"""
	Main grid map generation function
	"""
	assert(is_clear(), "Grid is already loaded")
	reset_data()

	new_map_data.apply_data()

	# sentinels appear on both sides
	grid_width += (SENTINEL_BORDER_SIZE * 2)
	grid_height += (SENTINEL_BORDER_SIZE * 2)

	init_tile_grid()
	spawn_tiles()
	generate_special_tiles()

func to_bordered_coords(initial:Vector2i) -> Vector2i:
	return initial + Vector2i(SENTINEL_BORDER_SIZE, SENTINEL_BORDER_SIZE)

#endregion
