extends CanvasLayer


@export var world_map_tiles : Array[DataTile] = []
@export var map_to_load : GridBoard

enum map_type
{
	WORLD,
	BATTLE,
}

var current_map_type : map_type


@onready var empty_battle_map : BattleMap = load("res://Resources/Battle_Maps/empty.tres")
@onready var empty_world_map : WorldMap = load("res://Resources/World_Maps/empty2.tres")

@onready var current_brush : DataTile



# static func list_files_in_folder(folder_path : String, return_full_path : bool = false) -> Array[String]:
# 	var dir = DirAccess.open(folder_path)
# 	var scenes:Array[String] = []

# 	if dir:
# 		for file in dir.get_files():
# 			if return_full_path:
# 				scenes.append(folder_path + "/" + file)
# 			else:
# 				scenes.append(file)
# 	else:
# 		print("Error opening folder:", folder_path)
# 	dir = null
# 	return scenes


func _ready():
	var world_map_tiles_paths : Array[String] = TestTools.list_files_in_folder("res://Resources/World_tiles/", true)
	for world_map_tile in world_map_tiles_paths:
		world_map_tiles.append(load(world_map_tile))
	
	var box = get_node("VWorldBox")

	current_brush = world_map_tiles[0]

	for button in world_map_tiles:
		var new_button = TextureButton.new()

		new_button.texture_normal = ResourceLoader.load(button.texture_path)

		box.add_child(new_button)
		var lambda = func on_click():
			current_brush = button
		
		new_button.pressed.connect(lambda)  # self._button_pressed



func grid_input(cord : Vector2i):
	if current_map_type == map_type.WORLD:
		W_GRID.hex_grid[cord.x][cord.y].get_node("Sprite2D").texture = ResourceLoader.load(current_brush.texture_path)
	else:
		B_GRID.tile_grid[cord.x][cord.y].get_node("Sprite2D").texture = ResourceLoader.load(current_brush.texture_path)


func open_draw_menu():
	visible = true

func hide_draw_menu():
	visible = false

func _toggle_menu_status():
	visible = not visible

class test_hero:
	pass


#region Buttons:


func _on_load_map_pressed():
	assert(map_to_load != null, "there is no selected map to be loaded")

	if map_to_load is WorldMap:
		current_map_type = map_type.WORLD
		W_GRID.generate_grid(map_to_load)
	else:
		current_map_type = map_type.BATTLE
		B_GRID.generate_grid(map_to_load)



func _on_save_map_pressed():
	print("save map")
	var new_map
	if current_map_type == map_type.WORLD:
		new_map = WorldMap.new()
	else:
		new_map = BattleMap.new()

	var grid_data = []

	for tile_row in B_GRID.tile_grid:
		var current_row = []
		grid_data.append(current_row)
		for tile in tile_row:
			var new_data_tile = DataTile.create_data_tile(tile)

			current_row.append(new_data_tile)


	new_map.grid_data = grid_data

	new_map.grid_height = grid_data.size()
	new_map.grid_width = grid_data[0].size()



	var save_path = "res://Resources/Battle_Maps/empty2.tres"
	ResourceSaver.save(new_map, save_path)

	print("end save map")
	


func _on_new_world_map_pressed():
	current_map_type = map_type.WORLD
	W_GRID.generate_grid(empty_world_map)


func _on_new_battle_map_pressed():
	current_map_type = map_type.BATTLE
	B_GRID.generate_grid(empty_battle_map)


#endregion


