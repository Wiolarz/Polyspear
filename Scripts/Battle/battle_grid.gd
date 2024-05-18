# Singleton B-GRID
extends GridManager

var tile_grid : GenericHexGrid # Grid<TileForm>

func load_map(map : DataBattleMap) -> void:
	assert(is_clear(), "cannot load map, map already loaded")
	tile_grid = GenericHexGrid.new(map.grid_width, map.grid_height, null)
	for x in range(map.grid_width):
		for y in range(map.grid_height):
			var coord = Vector2i(x, y)
			var data = map.grid_data[x][y] as DataTile
			var tile_form = TileForm.create_battle_tile(data, coord)
			tile_grid.set_hex(coord, tile_form)
			tile_form.position = to_position(coord)
			add_child(tile_form)


func is_clear() -> bool:
	return get_child_count() == 0 and not tile_grid


func reset_data():
	tile_grid = null
	for c in get_children():
		c.queue_free()
		remove_child(c)


## for map editor only
func paint(coord : Vector2i, brush : DataTile) -> void:
	var tile = tile_grid.get_hex(coord) as TileForm
	tile.paint(brush)
