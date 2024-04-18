# Singleton - W_GRID
extends GridManager


var max_player_number : int

var cities: Array[City] = []

#region Tools

func place_army(army : ArmyOnWorldMap, coord : Vector2i):
	assert(unit_grid[coord.x][coord.y] == null, "can't place 2 armies on the same field")
	army.army_data.cord = coord
	unit_grid[coord.x][coord.y] = army
	army.position = tile_at(coord).position


func change_hero_position(hero, coord : Vector2i):

	unit_grid[hero.cord.x][hero.cord.y] = null # clean your previous location
	unit_grid[coord.x][coord.y] = hero

	# Move visuals of the unit
	hero.move(tile_grid[coord.x][coord.y])
	

func remove_hero(hero):

	var cord : Vector2i = hero.cord
	unit_grid[cord.x][cord.y] = null # Remove unit from gameplay grid

	hero.destroy()

#endregion


#region Coordinates Tools

func is_moveable(cord : Vector2i):
	return tile_grid[cord.x][cord.y].type in [ \
		E.to_name(E.WorldMapTiles.EMPTY),
		E.to_name(E.WorldMapTiles.CITY),
		E.to_name(E.WorldMapTiles.PLACE),
	]

func get_tile_controller(cord : Vector2i):
	var hero = get_hero(cord)
	if hero != null:
		return hero.controller
	return null # tile_grid[cord.x][cord.y].controller

func get_battle_map(_cord : Vector2i):
	return load("res://Resources/Battle/Battle_Maps/basic5x5.tres")

func get_army(cord : Vector2i) -> ArmyOnWorldMap:
	return unit_grid[cord.x][cord.y]

func is_city(cord : Vector2i) -> bool:
	var tile = tile_at(cord)
	return tile.type == "orc_city" or tile.type == "elf_city"

func get_city(coord : Vector2i) -> City:
	for c in cities:
		if c.coord == coord:
			return c
	if not is_city(coord):
		return null
	var c = City.new()
	c.coord = coord
	cities.append(c)
	return c

func get_hero(coord : Vector2i):
	var army = get_army(coord)
	if army!= null and army.army_data.hero != null:
		return army
	return null


func is_enemy_present(cord : Vector2i, player):
	if get_tile_controller(cord) == player:
		return false
	if get_army(cord) == null:
		return false 
	return true


func get_interactable_type(cord : Vector2i) -> String:
	var army = get_army(cord)
	if army != null:
		return "army"
	if is_city(cord):
		return "city"
	
	return "empty"

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
