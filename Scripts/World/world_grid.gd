# Singleton - W_GRID
extends GridManager

var max_player_number : int

var grid_width : int
var	grid_height : int

var tile_grid : GenericHexGrid # Grid<TileForm>
var unit_grid : GenericHexGrid # Grid<ArmyForm>
var places_grid : GenericHexGrid # Grid<Place>

func load_map(world_map : DataWorldMap) -> void:
	assert(is_clear(), "cannot load map, map already loaded")
	grid_width = world_map.grid_width
	grid_height = world_map.grid_height
	tile_grid = GenericHexGrid.new(grid_width, grid_height, null)
	unit_grid = GenericHexGrid.new(grid_width, grid_height, null)
	places_grid = GenericHexGrid.new(grid_width, grid_height, null)

	for x in range(grid_width):
		for y in range(grid_height):
			var coord = Vector2i(x, y)
			var data = world_map.grid_data[x][y] as DataTile
			var place : Place = Place.create_place(data, coord)
			var tile_form = TileForm.create_world_tile(data, coord, place)
			tile_form.position = to_position(coord)
			add_child(tile_form)

			tile_grid.set_hex(coord, tile_form)
			places_grid.set_hex(coord, place)
			if place:
				place.on_game_started()

#region Tools


func place_army(army : ArmyForm, coord : Vector2i) -> void:
	assert(not unit_grid.get_hex(coord), "can't place 2 armies on the same field")
	unit_grid.set_hex(coord, army)
	var tile = tile_grid.get_hex(coord)
	assert(tile, "can't place armies on non existing tile " + str(coord))
	army.place_on(tile)


func get_army(coord : Vector2i) -> ArmyForm:
	return unit_grid.get_hex(coord)


func get_hero(coord : Vector2i) -> Hero:
	var army = get_army(coord)
	if army != null and army.entity.hero != null:
		return army
	return null


func change_hero_position(hero : ArmyForm, coord : Vector2i) -> void:
	assert(unit_grid.get_hex(hero.coord) == hero, "hero coord desync")
	unit_grid.set_hex(hero.coord, null) # clean your previous location
	unit_grid.set_hex(coord, hero)
	# Move visuals of the unit
	var tile = tile_grid.get_hex(coord)
	assert(tile, "can't place armies on non existing tile " + str(coord))
	hero.move(tile)


func remove_hero(hero : ArmyForm) -> void:
	assert(unit_grid.get_hex(hero.coord) == hero, "hero coord desync")
	unit_grid.set_hex(hero.coord, null)
	hero.destroy()

#endregion


#region Coordinates Tools

func is_moveable(coord : Vector2i):
	var tile = tile_grid.get_hex(coord)
	return tile.type in CFG.WORLD_MOVEABLE_TILES


func get_tile_controller(coord : Vector2i) -> Player:
	var hero = get_hero(coord)
	if hero:
		return hero.controller
	var place = get_place(coord)
	if place:
		return place.controller
	return null


func get_battle_map(_coord : Vector2i) -> DataBattleMap:
	return CFG.DEFAULT_BATTLE_MAP


func is_city(coord : Vector2i) -> bool:
	return get_city(coord) != null


func get_city(coord : Vector2i) -> City:
	return get_place(coord) as City


func get_place(coord : Vector2i) -> Place:
	return places_grid.get_hex(coord) as Place


func is_enemy_present(coord : Vector2i, player : Player) -> bool:
	var army = get_army(coord)
	if not army:
		return false
	if army.controller == player: #TEMP should check for allies
		return false
	return true


func get_interactable_type(coord : Vector2i) -> String:
	var army = get_army(coord)
	if army != null:
		return "army"
	if is_city(coord):
		return "city"

	return "empty"

#endregion


#region Generate Grid

func is_clear() -> bool:
	return not tile_grid and not unit_grid and not places_grid


func end_of_turn_callbacks(player : Player) -> void:
	#TODO make it nicer
	for x in range(grid_width):
		for y in range(grid_height):
			var coord = Vector2i(x,y)
			var a = get_army(coord)
			if a:
				a.on_end_of_turn(player)


## for map editor only
func paint(coord : Vector2i, brush : DataTile) -> void:
	var tile = tile_grid.get_hex(coord) as TileForm
	tile.paint(brush)


func reset_data() -> void:
	for c in get_children():
		c.queue_free()
		remove_child(c)
	tile_grid = null
	unit_grid = null
	places_grid = null
	grid_height = 0
	grid_height = 0

#endregion
