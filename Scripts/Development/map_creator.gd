extends CanvasLayer


@export var world_map_tiles : Array[DataTile] = []


@onready var SentineltHexTile : PackedScene = load("res://Scenes/HexTiles/BlackHexTile.tscn")
@onready var DefaultHexTile : PackedScene = load("res://Scenes/HexTiles/StoneHexTile.tscn")
@onready var AttackerHexTile : PackedScene = load("res://Scenes/HexTiles/GrassHexTile.tscn")
@onready var DefenderHexTile : PackedScene = load("res://Scenes/HexTiles/DirtHexTile.tscn")


@onready var new_map_battle_map : BattleMap = load("res://Resources/Battle_Maps/empty.tres")

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

	B_GRID.tile_grid[cord.x][cord.y].get_node("Sprite2D").texture = ResourceLoader.load(current_brush.texture_path)


func open_draw_menu():
	visible = true

func hide_draw_menu():
	visible = false

func _toggle_menu_status():
	visible = not visible




#region Buttons:
func _on_new_map_pressed():
	B_GRID.generate_grid(new_map_battle_map)


func _on_load_map_pressed():
	pass 


func _on_save_map_pressed():
	print("save map")

	var new_map = WorldMap.new()

	var grid_data = []

	for tile_row in B_GRID.tile_grid:
		var current_row = []
		grid_data.append(current_row)
		for tile in tile_row:
			var new_data_tile = DataTile.create_data_tile(tile)

			current_row.append(new_data_tile)


	new_map.grid_data = grid_data

	new_map.grid_width = 5



	var save_path = "res://Resources/Battle_Maps/empty2.tres"
	ResourceSaver.save(new_map, save_path)

	print("end save map")
	


# func _on_default_button_pressed():
# 	current_brush = DefaultHexTile

# func _on_sentinel_button_pressed():
# 	current_brush = SentineltHexTile

# func _on_spawn_1_button_pressed():
# 	current_brush = AttackerHexTile


# func _on_spawn_2_button_pressed():
# 	current_brush = DefenderHexTile


#endregion