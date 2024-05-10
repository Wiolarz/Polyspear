extends CanvasLayer

enum MapType
{
	WORLD,
	BATTLE,
}

@export var map_file_name_input : TextEdit

@export var new_map_width : int = 5
@export var new_map_height : int = 5


var current_map_type : MapType

var current_brush : DataTile
var current_button: TextureButton

@onready var tile_buttons_box : BoxContainer = $Scroll/TilesPickerBox
@onready var tiles_world : Array[String] = \
		FileSystemHelpers.list_files_in_folder(CFG.WORLD_MAP_TILES_PATH, true)
@onready var tiles_battle : Array[String] = \
		FileSystemHelpers.list_files_in_folder(CFG.BATTLE_MAP_TILES_PATH, true)


#region Setup

func _create_button(box : BoxContainer, map_tile : String):
	var tile = load(map_tile)

	var new_button = TextureButton.new()
	new_button.texture_normal = ResourceLoader.load(tile.texture_path)
	new_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT
	new_button.ignore_texture_size = true
	new_button.custom_minimum_size = Vector2(130,160)
	box.add_child(new_button)
	var lambda = func on_click():
		if current_button != null:
			current_button.modulate = Color.WHITE
		current_brush = tile
		current_button = new_button
		current_button.modulate = Color.DIM_GRAY

	new_button.pressed.connect(lambda)  # self._button_pressed


#endregion


#region Tools

## Called when user presses on the map tile
## Replaces target map tile with currently selected "brush" (map tile type)
func grid_input(coord : Vector2i) -> void:
	if current_map_type == MapType.WORLD:
		W_GRID.tile_grid[coord.x][coord.y].type = current_brush.type
		W_GRID.tile_grid[coord.x][coord.y].get_node("Sprite2D").texture = ResourceLoader.load(current_brush.texture_path)
	else:
		B_GRID.tile_grid[coord.x][coord.y].type = current_brush.type
		B_GRID.tile_grid[coord.x][coord.y].get_node("Sprite2D").texture = ResourceLoader.load(current_brush.texture_path)


func _set_grid_type(new_type : MapType) -> void:
	current_map_type = new_type
	_mark_button(new_type)
	var tile_set = tiles_world if new_type == MapType.WORLD else tiles_battle
	for b in tile_buttons_box.get_children():
		b.queue_free()
	for tile_path in tile_set:
		_create_button(tile_buttons_box, tile_path)
	# pick first tile as a default tile
	tile_buttons_box.get_child(0).pressed.emit()


func _mark_button(selected_type : MapType):
	if selected_type == MapType.WORLD:
		$MenuContainer/NewWorldMap.modulate = Color.FIREBRICK
		$MenuContainer/NewBattleMap.modulate = Color.WHITE
	else:
		$MenuContainer/NewBattleMap.modulate = Color.FIREBRICK
		$MenuContainer/NewWorldMap.modulate = Color.WHITE


func _optimize_grid_size(local_tile_grid : Array) -> Array:
	"""
	checks for the first and last non-sentinel tile placement in each grid row and column.
	Then it will remove all empty columns at map edges
	this function should be called during saving of a scene
	"""
	# # location of the first non sentinel tiles from:
	var left_pos : int = local_tile_grid.size()
	var right_pos : int = 0
	var top_pos : int = local_tile_grid[0].size()
	var bot_pos : int = 0
	for x in local_tile_grid.size():
		for y in local_tile_grid[0].size():
			if local_tile_grid[x][y].type != "sentinel":
				if left_pos > x:
					left_pos = x
				elif right_pos < x:
					right_pos = x
				if top_pos > y:
					top_pos = y
				if bot_pos < y:
					bot_pos = y
	for right in range(max(local_tile_grid.size() - right_pos - 1, 0)):
		local_tile_grid.pop_back()

	for left in range(max(left_pos, 0)):
		local_tile_grid.pop_front()

	var rows_at_the_back_to_remove : int = local_tile_grid[0].size() - bot_pos

	for column in local_tile_grid:
		for bot in range(max(rows_at_the_back_to_remove - 1, 0)):
			column.pop_back()

		for top in range(max(top_pos, 0)):
			column.pop_front()

	#print(left_pos, " ", right_pos, " ", top_pos, " ", bot_pos)
	return local_tile_grid


func open_draw_menu():
	visible = true
	_on_new_world_map_pressed()

#endregion


#region Buttons:

func _on_load_map_pressed():
	var map_path = CFG.WORLD_MAPS_PATH
	if current_map_type == MapType.BATTLE:
		map_path = CFG.BATTLE_MAPS_PATH
	map_path += map_file_name_input.text + ".tres"
	var map_to_load = load(map_path)
	assert(map_to_load != null, "there is no selected map to be loaded")
	WM.close_world()
	BM.reset_battle_manager()
	if map_to_load is DataWorldMap:
		_set_grid_type(MapType.WORLD)
		W_GRID.generate_grid(map_to_load)
	else:
		_set_grid_type(MapType.BATTLE)
		B_GRID.generate_grid(map_to_load)


func _on_save_map_pressed():
	print("save map")
	var map_save_name : String = map_file_name_input.text

	var new_map
	var local_tile_grid : Array
	var save_path
	if current_map_type == MapType.WORLD:
		new_map = DataWorldMap.new()
		local_tile_grid = W_GRID.tile_grid
		save_path = CFG.WORLD_MAPS_PATH + map_save_name + ".tres"
	else:
		new_map = DataBattleMap.new()
		local_tile_grid = B_GRID.tile_grid
		save_path = CFG.BATTLE_MAPS_PATH + map_save_name + ".tres"

	var grid_data = []

	local_tile_grid = _optimize_grid_size(local_tile_grid.duplicate(true))

	for tile_column in local_tile_grid:
		var current_column = []
		grid_data.append(current_column)
		for tile in tile_column:
			var new_data_tile = DataTile.create_data_tile(tile)

			current_column.append(new_data_tile)


	new_map.grid_data = grid_data

	new_map.grid_height = grid_data[0].size()
	new_map.grid_width = grid_data.size()

	ResourceSaver.save(new_map, save_path)

	print("end save map")


func _generate_empty_map(size_x : int = 5, size_y : int = 5) -> Array: # -> Array[Array[DataTile]]
	WM.close_world()
	BM.reset_battle_manager()
	var grid_data = []

	for tile_column in range(size_x):
		var current_column = []
		grid_data.append(current_column)
		for tile in range(size_y):
			var new_data_tile = load(CFG.SENTINEL_TILE_PATH)

			current_column.append(new_data_tile)

	return grid_data


func _on_new_world_map_pressed():
	_set_grid_type(MapType.WORLD)
	map_file_name_input.text = "new_world"

	var new_map = DataWorldMap.new()
	var grid_data = _generate_empty_map()
	new_map.grid_data = grid_data

	new_map.grid_height = grid_data.size()
	new_map.grid_width = grid_data[0].size()
	#print(new_map.grid_height, " ", new_map.grid_width)
	W_GRID.reset_data()
	W_GRID.generate_grid(new_map)


func _on_new_battle_map_pressed():
	_set_grid_type(MapType.BATTLE)
	map_file_name_input.text = "new_battleground"

	var grid_data = _generate_empty_map()

	var new_map = DataBattleMap.new()

	new_map.grid_data = grid_data

	new_map.grid_height = grid_data.size()
	new_map.grid_width = grid_data[0].size()
	#print(new_map.grid_height, " ", new_map.grid_width)
	B_GRID.reset_data()
	B_GRID.generate_grid(new_map)


func _on_open_button_pressed():
	$FileDialog.root_subfolder = CFG.WORLD_MAPS_PATH \
			if current_map_type == MapType.WORLD else CFG.BATTLE_MAPS_PATH
	$FileDialog.show()


func _on_file_dialog_file_selected(path : String):
	map_file_name_input.text = path.get_file().trim_suffix(".tres")
	_on_load_map_pressed()


func _on_back_button_pressed():
	hide()
	IM.go_to_main_menu()

#endregion
