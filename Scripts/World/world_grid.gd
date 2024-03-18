# Singleton - W_GRID

extends GridManager


# Hard coding of art files is a temporary solution until a decision how to approach treating background art will be made
@onready var SentineltHexTile : PackedScene = load("res://Scenes/HexTiles/BlackHexTile.tscn")
@onready var WallHexTile : PackedScene = load("res://Scenes/HexTiles/StoneHexTile.tscn")
@onready var DefaultHexTile : PackedScene = load("res://Scenes/HexTiles/GrassHexTile.tscn")

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

	for y in range(grid_height):
		for x in range(grid_width):
			var oddRow = y % 2 == 0 # Sentinel Rows add aditional row
			
			var XTilePos = x * TileHorizontalOffset + y * OddRowHorizontalOffset
			var YTilePos = y * TileVerticalOffset

			var newTileScene : PackedScene = get_tile_to_spawn(x, y, oddRow)
			var newTile = newTileScene.instantiate()

			add_child(newTile)
			
			var GRID = map_information.grid_data # TODOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO


			newTile.get_node("Sprite2D").texture = ResourceLoader.load(GRID[x][y].texture_path)


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


func get_tile_to_spawn(x : int, y : int, bOddRow : bool) -> PackedScene:


	


	var TileToSpawn = SentineltHexTile # Default value for hex tile is Sentinel Tile





	current_spawn = E.WorldMapTiles.SENTINEL

	if is_gameplay_tile(x, y, bOddRow):
		TileToSpawn = DefaultHexTile
		current_spawn = E.WorldMapTiles.EMPTY

		var FirstColumnStart : int = (grid_height / 2) + border_size - (y / 2)

		if (bOddRow and x == FirstColumnStart + 1) or (not bOddRow and x == FirstColumnStart): # first column
			TileToSpawn = WallHexTile
			current_spawn = E.WorldMapTiles.WALL
		elif (x == grid_width - border_size - 1  - (y / 2)): # last column
			TileToSpawn = WallHexTile
			current_spawn = E.WorldMapTiles.WALL
			
	return TileToSpawn


func reset_data():
	hex_grid = []
	hero_grid = []

#endregion
