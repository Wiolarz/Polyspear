# Singleton - W_GRID
extends GridNode2D

var grid_width : int
var grid_height : int

var tile_grid : GenericHexGrid # Grid<TileForm>
var unit_grid : GenericHexGrid # Grid<ArmyForm>
var places_grid : GenericHexGrid # Grid<Place>
# TODO make naming consistent -- all in plural form or none


#region basic typed helpers

func get_army_form(coord : Vector2i) -> ArmyForm:
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
	var army = get_army_form(coord)
	if army:
		return army.controller
	var place = get_place(coord)
	if place:
		return place.controller
	return null


func get_city(coord : Vector2i) -> City:
	assert(false, "removed from here")
	return null


func get_all_places() -> Array[Place]:
	assert(false, "removed from here")
	return []


func is_enemy_present(coord : Vector2i, player : Player) -> bool:
	var army := get_army_form(coord)
	if not army:
		return false
	if army.controller == player: #TEMP should check for allies
		return false
	return true

func has_army(coord : Vector2i) -> bool:
	return get_army_form(coord) != null

#endregion


#region Generate Grid

func is_clear() -> bool:
	return tile_grid == null and unit_grid == null and places_grid == null


func end_of_turn_callbacks(player : Player) -> void:
	assert(false, "removed from here")


func _end_of_round_callbacks() -> void:
	assert(false, "removed from here")


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
