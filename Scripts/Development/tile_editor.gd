extends CanvasLayer

## currently edited unit data
## WARNING: do not change this until save is clicked
## not saved changes are kept on `dirty_changes`
var edited_tile : DataTile

var dirty_changes : DataTile = DataTile.new()

## order of symbols here is the same order as in symbol pickers
var all_data_symbols : Array[DataSymbol] = []

## Dictionary int -> String (DataTile path)
var browser_tree_id_to_tile_path : Dictionary = {}

## prepared resized texture for open button in browser
var open_button_texture : Texture2D

## label showing path to currently edited data unit
@onready var currently_edited_label : Label = \
	$HBoxContainer/Edition/VBoxContainer/Top/PanelContainer/TileName

## unit form for preview and storing unsaved changes temporarily
@onready var tile_preview_form : TileForm = \
	$HBoxContainer/Edition/VBoxContainer/Preview/Center/TilePreview

## try display for selecting unit to edit
@onready var tile_browser_tree : Tree = $HBoxContainer/TileBrowserTree

@onready var symbol_container : Control = $HBoxContainer/Edition/VBoxContainer/Preview/Center

func _ready():
	_load_open_button_texture()
	_load_tile()

## resizes texture for open button in unit browser tree
func _load_open_button_texture():
	var base_texture = load("res://Art/old/push.png")
	var image = base_texture.get_image()
	image.resize(32, 32)
	open_button_texture = ImageTexture.create_from_image(image)

## initializes `tile_browser_tree` and `browser_tree_id_to_tile_path`
## tree buttons get ids corresponding to indexes in that array
func _load_tile():
	tile_browser_tree.button_clicked.connect(_on_browser_open_button_clicked)
	tile_browser_tree.item_activated.connect(_on_browser_item_activated)
	var root = tile_browser_tree.create_item()
	tile_browser_tree.hide_root = true
	var dir = DirAccess.open(CFG.BATTLE_MAP_TILES_PATH)
	if dir:
		next_tile_id = 0
		_load_tile_dir_recursive(dir, root);
	else:
		push_error("Error opening folder: ", CFG.BATTLE_MAP_TILES_PATH)

## field to allow keeping proper ids count
## during recursive calls in load_tiles_dir
var next_tile_id : int = 0


## initializes `tile_browser_tree` and `browser_tree_id_to_tile_path`
## tree buttons get ids corresponding to indexes in that array
func _load_tile_dir_recursive(dir : DirAccess, parent : TreeItem):
	for file in dir.get_files():
		var file_in_the_tree = tile_browser_tree.create_item(parent)
		file_in_the_tree.set_text(0, file)
		file_in_the_tree.add_button( \
				0, open_button_texture, next_tile_id, false, "tooltip")

		browser_tree_id_to_tile_path[next_tile_id] = \
				dir.get_current_dir() + "/" + file
		#print("loaded ", browser_tree_id_to_tile_path[next_tile_id], \
				#" on id ", next_tile_id)

		next_tile_id += 1

	for child_directory in dir.get_directories():
		var directory_in_the_tree = tile_browser_tree.create_item(parent)
		directory_in_the_tree.set_text(0, child_directory)
		directory_in_the_tree.set_custom_bg_color(0, Color.DARK_BLUE)
		directory_in_the_tree.set_selectable(0, false)

		var child_dir_access = DirAccess.open( \
				dir.get_current_dir()+"/"+child_directory)
		_load_tile_dir_recursive(child_dir_access, directory_in_the_tree)


## load tile when clicking open button
func _on_browser_open_button_clicked(_item, _column, id:int, _mouse_button):
	load_tile(browser_tree_id_to_tile_path[id])


## load tile when double clicking or pressing enter
func _on_browser_item_activated():
	var selected = tile_browser_tree.get_selected()
	var open_button_id = selected.get_button_id(0, 0)
	load_tile(browser_tree_id_to_tile_path[open_button_id])

## Sets DataTile on specified path as `edited_tile`
## Updates `tile_preview_form`, `symbol_pickers`, `currently_edited_label` etc
func load_tile(path : String):
	var data = load(path)
	edited_tile = data as DataTile
	dirty_changes = edited_tile.duplicate()

	currently_edited_label.text = edited_tile.resource_path

	tile_preview_form.paint(dirty_changes)


## shows art picking dialog
func _on_pick_art_button_pressed():
	$PickArtDialog.show()


## applies new art to `tile_preview_form`
func _on_pick_art_dialog_file_selected(path):
	dirty_changes.texture_path = path
	tile_preview_form._set_texture(load(path))


## applies changes in `tile_preview_form` to `edited_tile` resource
func _on_save_pressed():
	if edited_tile == null or edited_tile.resource_path.is_empty():
		push_error("can only edit existing units, open a unit first")
		return
	edited_tile.texture_path = dirty_changes.texture_path
	ResourceSaver.save(edited_tile, edited_tile.resource_path)
	# WARNING clears uids
	# see https://github.com/godotengine/godot/issues/83259
	# use uid_fixer script to fix


## return to main menu
func _on_back_button_pressed():
	hide()
	IM.go_to_main_menu()
