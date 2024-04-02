# Singleton - W_GRID
extends GridManager



var max_player_number : int



#region Tools

func change_hero_position(hero, cord : Vector2i):

	unit_grid[hero.cord.x][hero.cord.y] = null# clean your previous location
	unit_grid[cord.x][cord.y] = hero

	hero.cord = cord
	
	# Move visuals of the unit
	hero.move(unit_grid[cord.x][cord.y])
	



func remove_hero(hero):

	var cord : Vector2i = hero.cord
	unit_grid[cord.x][cord.y] = null # Remove unit from gameplay grid

	hero.destroy()

#endregion


#region Coordinates Tools

func is_moveable(cord : Vector2i):
	if tile_grid[cord.x][cord.y].type in \
		[E.WorldMapTiles.EMPTY, E.WorldMapTiles.CITY,  E.WorldMapTiles.PLACE]:
			return true
	
	return false

func get_tile_controller(cord : Vector2i):
	var hero = get_hero(cord)
	if hero != null:
		return hero.controller
	return tile_grid[cord.x][cord.y].controller


func get_army(cord : Vector2i):
	var hero = get_hero(cord)
	if hero != null:
		return hero.army
	return tile_grid[cord.x][cord.y].defender_army


func get_city(cord : Vector2i) -> City:
	var city = tile_grid[cord.x][cord.y]
	if city is City:
		return city
	return null

func get_hero(cord : Vector2i):
	return unit_grid[cord.x][cord.y]

#endregion


#region Generate Grid
func is_clear() -> bool:
	return tile_grid.size() == 0 and unit_grid.size() == 0

func init_tile_grid() -> void:
	for i in range(grid_width):
		tile_grid.append([])
		unit_grid.append([])
		for j in range(grid_height):
			unit_grid[i].append(null)
			tile_grid[i].append(null)



			


func reset_data():
	super.reset_data()

#endregion
