class_name ArtEditor
extends CanvasLayer

# TODO load first resource at start


var resource_directory_path : String

## field to allow keeping proper ids count
## during recursive calls in load_tiles_dir
var next_resource_id : int = 0

## currently edited unit data
## WARNING: do not change this until save is clicked
## not saved changes are kept on `dirty_changes`
var edited_resource : Resource

var dirty_changes : Resource

## Dictionary int -> String (DataTile path)
var browser_tree_id_to_resource_path : Dictionary = {}

## prepared resized texture for open button in browser
var open_button_texture : Texture2D

## label showing path to currently edited data unit
@onready var currently_edited_label : Label = \
	$HBoxContainer/Edition/VBoxContainer/Top/PanelContainer/ResourceName

## unit form for preview and storing unsaved changes temporarily
@onready var resource_preview_form : Node2D = \
	$HBoxContainer/Edition/VBoxContainer/Preview/Center/ResourcePreview

## try display for selecting unit to edit
@onready var resource_browser_tree : Tree = $HBoxContainer/ResourceBrowserTree

#region INIT

func _ready():
	_load_open_button_texture()
	_init_resource_type()
	_load_resources()


## resizes texture for open button in resource browser tree
func _load_open_button_texture():
	var base_texture = load("res://Art/old/push.png")
	var image = base_texture.get_image()
	image.resize(32, 32)
	open_button_texture = ImageTexture.create_from_image(image)


## initializes `resource_browser_tree` and `browser_tree_id_to_resource_path`
## tree buttons get ids corresponding to indexes in that array
func _load_resources():
	resource_browser_tree.button_clicked.connect(_on_browser_open_button_clicked)
	resource_browser_tree.item_activated.connect(_on_browser_item_activated)
	var root = resource_browser_tree.create_item()
	resource_browser_tree.hide_root = true
	var dir = DirAccess.open(resource_directory_path)
	if dir:
		next_resource_id = 0
		_load_resources_dir_recursive(dir, root);
	else:
		push_error("Error opening folder: ", resource_directory_path)


## initializes `resource_browser_tree` and `browser_tree_id_to_resource_path`
## tree buttons get ids corresponding to indexes in that array
func _load_resources_dir_recursive(dir : DirAccess, parent : TreeItem):
	for file in dir.get_files():
		var file_in_the_tree = resource_browser_tree.create_item(parent)
		file_in_the_tree.set_text(0, file)
		file_in_the_tree.add_button( \
				0, open_button_texture, next_resource_id, false, "tooltip")

		browser_tree_id_to_resource_path[next_resource_id] = \
				dir.get_current_dir() + "/" + file
		#print("loaded ", browser_tree_id_to_resource_path[next_resource_id], \
				#" on id ", next_resource_id)

		next_resource_id += 1

	for child_directory in dir.get_directories():
		var directory_in_the_tree = resource_browser_tree.create_item(parent)
		directory_in_the_tree.set_text(0, child_directory)
		directory_in_the_tree.set_custom_bg_color(0, Color.DARK_BLUE)
		directory_in_the_tree.set_selectable(0, false)

		var child_dir_access = DirAccess.open( \
				dir.get_current_dir()+"/"+child_directory)
		_load_resources_dir_recursive(child_dir_access, directory_in_the_tree)

#endregion INIT


#region Overrideable functions

func _init_resource_type() -> void:
	pass


func apply_texture_to_preview() -> void:
	pass

func save_resource() -> void:
	edited_resource.texture_path = dirty_changes.texture_path
	ResourceSaver.save(edited_resource, edited_resource.resource_path)
	# WARNING clears uids
	# see https://github.com/godotengine/godot/issues/83259
	# use uid_fixer script to fix
	pass

#endregion Overrideable functions


#region Buttons

## Sets DataTile on specified path as `edited_resource`
## Updates `resource_preview_form`, `symbol_pickers`, `currently_edited_label` etc
func load_resource(path : String):
	var data = load(path)
	edited_resource = data
	dirty_changes = edited_resource.duplicate()

	currently_edited_label.text = edited_resource.resource_path

	apply_texture_to_preview()


## load resource when clicking open button
func _on_browser_open_button_clicked(_item, _column, id:int, _mouse_button):
	load_resource(browser_tree_id_to_resource_path[id])


## load tile when double clicking or pressing enter
func _on_browser_item_activated():
	var selected = resource_browser_tree.get_selected()
	var open_button_id = selected.get_button_id(0, 0)
	load_resource(browser_tree_id_to_resource_path[open_button_id])


## shows art picking dialog
func _on_pick_art_button_pressed():
	$PickArtDialog.show()


## applies new art to the edited resource
func _on_pick_art_dialog_file_selected(path : String):
	dirty_changes.texture_path = path
	resource_preview_form._set_texture(load(path))


## applies changes in `resource_preview_form` to `edited_resource` resource
func _on_save_pressed():
	assert(edited_resource and not edited_resource.resource_path.is_empty(), "can only edit existing resources, open a resource first")
	save_resource()


## return to main menu
func _on_back_button_pressed():
	hide()
	IM.go_to_main_menu()

#endregion Buttons
