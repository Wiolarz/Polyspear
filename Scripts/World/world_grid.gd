# Singleton - W_GRID

extends GridManager


# Collision scene
@onready var BASIC_HEX_TILE : PackedScene = load("res://Scenes/HexTiles/BasicHexTile.tscn")


var max_player_number : int

var hex_grid : Array = []  # Array[Array[Place]]
var hero_grid : Array = [] # Array[Array[Hero]]


var current_spawn : E.WorldMapTiles = E.WorldMapTiles.SENTINEL


#region Tools

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

#endregion


#region Coordinates Tools

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
	return hex_grid[cord.x][cord.y].defender_army


func get_city(cord : Vector2i) -> City:
	var city = hex_grid[cord.x][cord.y]
	if city is City:
		return city
	return null

func get_hero(cord : Vector2i):
	return hero_grid[cord.x][cord.y]

#endregion


#region Generate Grid
func is_clear() -> bool:
	return hex_grid.size() == 0 and hero_grid.size() == 0

func init_hex_grid() -> void:
	for i in range(grid_width):
		hex_grid.append([])
		hero_grid.append([])
		for j in range(grid_height):
			hero_grid[i].append(null)
			hex_grid[i].append(null)


func spawn_tiles() -> void:

	#for row in map_information.grid_data:
	#	for tile in row:
	
	var grid = map_information.grid_data

	for y in range(grid_height):
		for x in range(grid_width):
			var odd_row = y % 2 == 0 # Sentinel Rows add aditional row

			var x_tile_pos = x * TileHorizontalOffset + y * OddRowHorizontalOffset
			var y_tile_pos = y * TileVerticalOffset

			var new_tile_scene : PackedScene = BASIC_HEX_TILE
			var new_tile = new_tile_scene.instantiate()
			add_child(new_tile)
			if is_gameplay_tile(x, y, odd_row):
				var start : int = floor(grid_height / 2)# axial start position
				var gameplay_width_start : int = start + border_size - floor(y / 2)
				var gameplay_height_start : int = border_size

				var data_x = x - gameplay_width_start
				var data_y = y - gameplay_height_start

				new_tile.get_node("Sprite2D").texture = ResourceLoader.load(grid[data_x][data_y].texture_path)
				new_tile.type = grid[data_x][data_y].type


			new_tile.global_position.x = x_tile_pos
			new_tile.global_position.y = y_tile_pos

			new_tile.cord = Vector2i(x, y)
			match new_tile.type:
				"sentinel":
					new_tile.name = "Sentinel_HexTile"

				"empty":
					new_tile.name = "Empty_HexTile"
			
				"wall":
					new_tile.name = "Wall_HexTile"


			new_tile.tile_type = current_spawn

			hex_grid[x][y] = new_tile


func reset_data():
	hex_grid = []
	hero_grid = []

#endregion
