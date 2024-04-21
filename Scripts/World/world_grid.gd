# Singleton - W_GRID
extends GridManager


var max_player_number : int

var cities: Array[City] = [] # TODO remove
var places : Array = [] # Array[Array[Place]]


#region Tools

func place_army(army : ArmyOnWorldMap, coord : Vector2i):
	assert(unit_grid[coord.x][coord.y] == null, "can't place 2 armies on the same field")
	army.army_data.coord = coord
	unit_grid[coord.x][coord.y] = army
	army.position = tile_at(coord).position


func change_hero_position(hero, coord : Vector2i):
	unit_grid[hero.coord.x][hero.coord.y] = null # clean your previous location
	unit_grid[coord.x][coord.y] = hero

	# Move visuals of the unit
	hero.move(tile_grid[coord.x][coord.y])


func remove_hero(hero):
	var coord : Vector2i = hero.coord
	unit_grid[coord.x][coord.y] = null # Remove unit from gameplay grid

	hero.destroy()

#endregion


#region Coordinates Tools

func is_moveable(coord : Vector2i):
	return tile_grid[coord.x][coord.y].type in [ \
		"empty",
		"iron_mine",
		"sawmill",
		"ruby_cave",
	]


func get_tile_controller(coord : Vector2i) -> Player:
	var hero = get_hero(coord)
	if hero != null:
		return hero.controller
	var place = places[coord.x][coord.y]
	if place != null:
		return place.controller
	return null


func get_battle_map(_coord : Vector2i) -> DataBattleMap:
	return CFG.DEFAULT_BATTLE_MAP

func get_army(coord : Vector2i) -> ArmyOnWorldMap:
	return unit_grid[coord.x][coord.y]


func is_city(coord : Vector2i) -> bool: #TODO
	return get_city(coord) != null


func get_city(coord : Vector2i) -> City:
	return places[coord.x][coord.y] as City


func get_hero(coord : Vector2i):
	var army = get_army(coord)
	if army != null and army.army_data.hero != null:
		return army
	return null


func is_enemy_present(coord : Vector2i, player : Player) -> bool:
	if get_tile_controller(coord) == player:
		return false
	elif get_army(coord) == null:
		return false
	return true


func get_interactable_type(coord : Vector2i) -> String:
	var army = get_army(coord)
	if army != null:
		return "army"
	elif is_city(coord):
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
		places.append([])
		for j in range(grid_height):
			unit_grid[i].append(null)
			tile_grid[i].append(null)
			places[i].append(null)


func generate_special_tiles() -> void:
	for x in map_information.grid_data.size():
		for y in map_information.grid_data[0].size():
			var coords = Vector2i( \
				x + W_GRID.border_size, \
				y + W_GRID.border_size)
			var place : Place = Place.create_place( \
				map_information.grid_data[x][y])
			places[coords.x][coords.y] = place
			W_GRID.tile_at(coords).place = place


func reset_data() -> void:
	super.reset_data()

#endregion
