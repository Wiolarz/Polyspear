# Singleton - W_GRID
extends GridNode2D

var grid_width : int
var grid_height : int

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
			var coord := Vector2i(x, y)
			var data : DataTile = world_map.grid_data[x][y]
			var place : Place = Place.create_place(data, coord)
			var tile_form := TileForm.create_world_tile(data, coord, place)
			tile_form.position = to_position(coord)
			add_child(tile_form)

			tile_grid.set_hex(coord, tile_form)
			places_grid.set_hex(coord, place)
			if place:
				place.on_game_started()


#region basic typed helpers

## TODO rename `get_army_form`

func get_army(coord : Vector2i) -> ArmyForm:
	return unit_grid.get_hex(coord)


func get_place(coord : Vector2i) -> Place:
	return places_grid.get_hex(coord)


func get_tile_form(coord : Vector2i) -> TileForm:
	return tile_grid.get_hex(coord)


#endregion


#region Tools

func place_army(army : ArmyForm, coord : Vector2i) -> void:
	assert(not unit_grid.get_hex(coord), "can't place 2 armies on the same field")
	unit_grid.set_hex(coord, army)
	var tile := get_tile_form(coord)
	assert(tile, "can't place armies on non existing tile " + str(coord))
	army.place_on(tile)


func remove_army(army : ArmyForm) -> void:
	assert(unit_grid.get_hex(army.coord) == army, "army coord desync")
	unit_grid.set_hex(army.coord, null)


func change_army_position(army : ArmyForm, coord : Vector2i) -> void:
	assert(unit_grid.get_hex(army.coord) == army, "army coord desync")
	unit_grid.set_hex(army.coord, null) # clean your previous location
	unit_grid.set_hex(coord, army)
	# Move visuals of the unit
	var tile := get_tile_form(coord)
	assert(tile, "can't place armies on non existing tile " + str(coord))
	army.move(tile)

#endregion


#region Coordinates Tools

func is_movable(coord : Vector2i):
	var tile := get_tile_form(coord)
	return tile.type in CFG.WORLD_MOVABLE_TILES


func get_tile_controller(coord : Vector2i) -> Player:
	var army = get_army(coord)
	if army:
		return army.controller
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


func get_all_places() -> Array[Place]:
	var result:Array[Place] = []
	for x in range(grid_width):
		for y in range(grid_height):
			var coord := Vector2i(x, y)
			var place := get_place(coord)
			if place:
				result.append(place)
	return result


func is_enemy_present(coord : Vector2i, player : Player) -> bool:
	var army := get_army(coord)
	if not army:
		return false
	if army.controller == player: #TEMP should check for allies
		return false
	return true

func has_army(coord : Vector2i) -> bool:
	return get_army(coord) != null


func get_interactable_type(coord : Vector2i) -> String:
	if has_army(coord):
		return "army"

	if is_city(coord):
		return "city"

	return "empty"

#endregion


#region Generate Grid

func is_clear() -> bool:
	return tile_grid == null and unit_grid == null and places_grid == null


func end_of_turn_callbacks(player : Player) -> void:
	#TODO make it nicer
	for x in range(grid_width):
		for y in range(grid_height):
			var coord = Vector2i(x,y)
			var army := get_army(coord)
			if army:
				army.on_end_of_turn(player)


func _end_of_round_callbacks() -> void:
	for place in get_all_places():
		place.on_end_of_turn()


## for map editor only
func paint(coord : Vector2i, brush : DataTile) -> void:
	var tile := get_tile_form(coord)
	tile.paint(brush)


func reset_data() -> void:
	for child in get_children():
		child.queue_free()
		remove_child(child)
	tile_grid = null
	unit_grid = null
	places_grid = null
	grid_height = 0
	grid_width = 0


func get_bounds_global_position() -> Rect2:
	if is_clear():
		push_warning("asking not initialized grid for camera bounding box")
		return Rect2(0, 0, 0, 0)
	var top_left_tile_form := get_tile_form(Vector2i(0,0))
	var bottom_right_tile_form := get_tile_form(Vector2i(grid_width-1, grid_height-1))
	var size : Vector2 = bottom_right_tile_form.global_position - top_left_tile_form.global_position
	return Rect2(top_left_tile_form.global_position, size)

#endregion
