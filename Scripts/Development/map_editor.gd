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

func _create_button(map_tile : String) -> TextureButton:
	var tile = load(map_tile)

	var new_button = TextureButton.new()
	new_button.texture_normal = ResourceLoader.load(tile.texture_path)
	new_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT
	new_button.ignore_texture_size = true
	new_button.custom_minimum_size = Vector2(130,160)

	var lambda = func on_click():
		if current_button != null:
			current_button.modulate = Color.WHITE
		current_brush = tile
		current_button = new_button
		current_button.modulate = Color.DIM_GRAY

	new_button.pressed.connect(lambda)  # self._button_pressed
	return new_button

#endregion


#region Tools

## Called when user presses on the map tile
## Replaces target map tile with currently selected "brush" (map tile type)
func grid_input(coord : Vector2i) -> void:
	if current_map_type == MapType.WORLD:
		W_GRID.paint(coord, current_brush)
	else:
		BM.paint(coord, current_brush)


func _set_grid_type(new_type : MapType) -> void:
	current_map_type = new_type
	_mark_button(new_type)
	var tile_set = tiles_world if new_type == MapType.WORLD else tiles_battle
	for b in tile_buttons_box.get_children():
		b.queue_free()
	var new_buttons = []
	for tile_path in tile_set:
		new_buttons.append(_create_button(tile_path))
	for b in new_buttons:
		tile_buttons_box.add_child(b)
	# pick first tile as a default tile
	new_buttons[0].pressed.emit()


func _mark_button(selected_type : MapType):
	if selected_type == MapType.WORLD:
		$LMenuContainer/NewWorldMap.modulate = Color.FIREBRICK
		$LMenuContainer/NewBattleMap.modulate = Color.WHITE
	else:
		$LMenuContainer/NewBattleMap.modulate = Color.FIREBRICK
		$LMenuContainer/NewWorldMap.modulate = Color.WHITE


func open_draw_menu():
	visible = true
	_on_new_world_map_pressed()

#endregion


#region Saving Map

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
	var found_any_tiles = false
	for x in local_tile_grid.size():
		for y in local_tile_grid[0].size():
			if local_tile_grid[x][y].type != "sentinel":
				found_any_tiles = true
				if left_pos > x:
					left_pos = x
				elif right_pos < x:
					right_pos = x
				if top_pos > y:
					top_pos = y
				if bot_pos < y:
					bot_pos = y
	if not found_any_tiles:
		push_warning("map without any tiles...")
		return [[]]

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


func _generate_world_max_player_number(_local_tile_grid : Array) -> int:
	return 2  # TEMP


func _generate_battle_players_slots(local_tile_grid : Array) -> Dictionary:
	var player_slots : Dictionary = {}
	for tile_column : Array in local_tile_grid:
		for tile : TileForm in tile_column:
			if tile.type.substr(1) == "_player_spawn":
				var player_idx : int = tile.type[0].to_int()
				if player_idx in player_slots.keys():
					player_slots[player_idx] += 1
				else:
					player_slots[player_idx] = 1
	return player_slots

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
	BM.unload_for_editor()
	if map_to_load is DataWorldMap:
		_set_grid_type(MapType.WORLD)
		W_GRID.load_map(map_to_load)
	else:
		_set_grid_type(MapType.BATTLE)
		BM.load_editor_map(map_to_load)


func get_battle_map(trim : bool = true) -> DataBattleMap:
	var result = DataBattleMap.new()
	result.grid_data = []

	var manager_grid_data = BM.editor_get_hexes_copy_as_array()
	if trim:
		manager_grid_data = _optimize_grid_size(manager_grid_data)
	for tile_column in manager_grid_data:
		var current_column = []
		for tile : TileForm in tile_column:
			current_column.append( DataTile.create_data_tile(tile))
		result.grid_data.append(current_column)

	result.grid_width = manager_grid_data.size()
	result.grid_height = manager_grid_data[0].size()
	var player_slots =  _generate_battle_players_slots(manager_grid_data)
	# print(player_slots)
	result.player_slots = player_slots
	result.max_player_number = player_slots.keys().size()
	return result


func get_world_map(trim : bool =  true) -> DataWorldMap:
	var result = DataWorldMap.new()
	result.grid_data = []

	var manager_grid_data = W_GRID.tile_grid.hexes.duplicate(true)
	if trim:
		manager_grid_data = _optimize_grid_size(manager_grid_data)
	for tile_column in manager_grid_data:
		var current_column = []
		for tile : TileForm in tile_column:
			current_column.append( DataTile.create_data_tile(tile))
		result.grid_data.append(current_column)

	result.grid_width = manager_grid_data.size()
	result.grid_height = manager_grid_data[0].size()
	result.max_player_number = _generate_world_max_player_number(manager_grid_data)

	return result


func _on_save_map_pressed():
	print("saving map")
	var map_file_name : String = map_file_name_input.text
	var new_map
	var save_path
	if current_map_type == MapType.WORLD:
		new_map = get_world_map()
		save_path = CFG.WORLD_MAPS_PATH + map_file_name + ".tres"
	else:
		new_map = get_battle_map()
		save_path = CFG.BATTLE_MAPS_PATH + map_file_name + ".tres"

	ResourceSaver.save(new_map, save_path)
	# WARNING clears uids
	# see https://github.com/godotengine/godot/issues/83259
	# use uid_fixer script to fix

	print("end save map")
	print("reloading map")
	_on_load_map_pressed()


func _generate_empty_map(size_x : int = 5, size_y : int = 5) -> Array: # -> Array[Array[DataTile]]
	WM.close_world()
	BM.unload_for_editor()
	var grid_data = []

	for tile_column in range(size_x):
		var current_column = []
		grid_data.append(current_column)
		for tile in range(size_y):
			current_column.append(create_empty_tile())

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
	W_GRID.load_map(new_map)


func _on_new_battle_map_pressed():
	_set_grid_type(MapType.BATTLE)
	map_file_name_input.text = "new_battleground"

	var new_map = DataBattleMap.new()
	var grid_data = _generate_empty_map()
	new_map.grid_data = grid_data

	new_map.grid_height = grid_data.size()
	new_map.grid_width = grid_data[0].size()
	#print(new_map.grid_height, " ", new_map.grid_width)
	BM.unload_for_editor()
	BM.load_editor_map(new_map)


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

func create_empty_tile() -> DataTile:
	return load(CFG.SENTINEL_TILE_PATH)


func _on_add_column_pressed():
	if current_map_type == MapType.WORLD:
		var new_map := get_world_map(false)
		new_map.grid_data.append(create_empty_row(new_map.grid_height))
		new_map.grid_width += 1
		WM.close_world()
		W_GRID.load_map(new_map)
	else:
		var new_map := get_battle_map(false)
		new_map.grid_data.append(create_empty_row(new_map.grid_height))
		new_map.grid_width += 1
		BM.unload_for_editor()
		BM.load_editor_map(new_map)


func create_empty_row(length : int) -> Array[DataTile]:
	var row: Array[DataTile] = []
	for x in length:
		row.append(create_empty_tile())
	return row


func _on_add_row_pressed():
	if current_map_type == MapType.WORLD:
		var new_map := get_world_map(false)
		for row in new_map.grid_data:
			row.append(create_empty_tile())
		new_map.grid_height += 1
		WM.close_world()
		W_GRID.load_map(new_map)
	else:
		var new_map := get_battle_map(false)
		for row in new_map.grid_data:
			row.append(create_empty_tile())
		new_map.grid_height += 1
		BM.unload_for_editor()
		BM.load_editor_map(new_map)
