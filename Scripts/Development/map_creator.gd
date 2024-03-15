extends CanvasLayer


@onready var SentineltHexTile : PackedScene = load("res://Scenes/HexTiles/BlackHexTile.tscn")
@onready var DefaultHexTile : PackedScene = load("res://Scenes/HexTiles/StoneHexTile.tscn")
@onready var AttackerHexTile : PackedScene = load("res://Scenes/HexTiles/GrassHexTile.tscn")
@onready var DefenderHexTile : PackedScene = load("res://Scenes/HexTiles/DirtHexTile.tscn")


@onready var new_map_battle_map : BattleMap = load("res://Resources/Battle_Maps/empty.tres")

@onready var current_brush : PackedScene = load("res://Scenes/HexTiles/BlackHexTile.tscn")




func grid_input(cord : Vector2i):
	var old_tile = B_GRID.tile_grid[cord.x][cord.y]

	var newTile = current_brush.instantiate()

	W_GRID.add_child(newTile)
	


	newTile.global_position.x = old_tile.position.x
	newTile.global_position.y = old_tile.position.y

	newTile.cord = old_tile.cord

	B_GRID.tile_grid[old_tile.cord.x][old_tile.cord.y] = newTile
	old_tile.queue_free()



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
	pass 


func _on_default_button_pressed():
	current_brush = DefaultHexTile

func _on_sentinel_button_pressed():
	current_brush = SentineltHexTile

func _on_spawn_1_button_pressed():
	current_brush = AttackerHexTile


func _on_spawn_2_button_pressed():
	current_brush = DefenderHexTile


#endregion