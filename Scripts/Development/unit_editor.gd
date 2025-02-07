extends CanvasLayer

## currently edited unit data
## WARNING: do not change this until save is clicked
## not saved changes are kept on `dirty_changes`
var edited_unit : DataUnit

var dirty_changes : DataUnit = DataUnit.new()

## order of symbols here is the same order as in symbol pickers
var all_data_symbols : Array[DataSymbol] = []

## Dictionary int -> String (DataUnit path)
var browser_tree_id_to_unit_path : Dictionary = {}

## prepared resized texture for open button in browser
var open_button_texture : Texture2D

## label showing path to currently edited data unit
@onready var currently_edited_label : Label = \
	$HBoxContainer/Edition/VBoxContainer/Top/PanelContainer/UnitName

## unit form for preview and storing unsaved changes temporarily
@onready var unit_preview_form : UnitForm = \
	$HBoxContainer/Edition/VBoxContainer/Preview/Center/UnitPreview

## try display for selecting unit to edit
@onready var unit_browser_tree : Tree = $HBoxContainer/UnitBrowserTree

## OptionButtons for picking symbols, ordered matching direction codes
@onready var symbol_pickers : Array[OptionButton] = [
	$HBoxContainer/Edition/VBoxContainer/Preview/Center/ChangeW,
	$HBoxContainer/Edition/VBoxContainer/Preview/Center/ChangeNW,
	$HBoxContainer/Edition/VBoxContainer/Preview/Center/ChangeNE,
	$HBoxContainer/Edition/VBoxContainer/Preview/Center/ChangeE,
	$HBoxContainer/Edition/VBoxContainer/Preview/Center/ChangeSE,
	$HBoxContainer/Edition/VBoxContainer/Preview/Center/ChangeSW,
]


func _ready():
	_load_all_data_symbols()
	_fill_symbol_pickers()
	_load_open_button_texture()
	_load_units()


## scan and collect all DataSymbol resources
## so they can be referred as int index for symbol pickers
func _load_all_data_symbols():
	var path = CFG.SYMBOLS_PATH
	var dir = DirAccess.open(path)
	for f in dir.get_files():
		all_data_symbols.append(load(path+f) as DataSymbol)


## adds items to all pickers, based on `all_data_symbols`
func _fill_symbol_pickers():
	var direction = 0
	for picker in symbol_pickers:
		fill_symbol_picker(picker, direction)
		direction += 1


## adds items to a picker, based on `all_data_symbols`
func fill_symbol_picker(picker : OptionButton, direction : int):
	picker.clear()
	for data_symbol in all_data_symbols:
		picker.add_item(E.symbol_to_name(data_symbol.type))
	# bind direction in callback
	var callback = func onSelected(_index):
		on_symbol_selected(direction, _index)
	picker.item_selected.connect(callback)


## resizes texture for open button in unit browser tree
func _load_open_button_texture():
	var base_texture = load("res://Art/old/push.png")
	var image = base_texture.get_image()
	image.resize(32, 32)
	open_button_texture = ImageTexture.create_from_image(image)


## initializes `unit_browser_tree` and `browser_tree_id_to_unit_path`
## tree buttons get ids corresponding to indexes in that array
func _load_units():
	unit_browser_tree.button_clicked.connect(_on_browser_open_button_clicked)
	unit_browser_tree.item_activated.connect(_on_browser_item_activated)
	var root = unit_browser_tree.create_item()
	unit_browser_tree.hide_root = true
	var dir = DirAccess.open(CFG.UNITS_PATH)
	if dir:
		next_unit_id = 0
		_load_units_dir_recursive(dir, root);
	else:
		push_error("Error opening folder: ", CFG.UNITS_PATH)

## field to allow keeping proper ids count
## during recursive calls in load_units_dir
var next_unit_id : int = 0


## initializes `unit_browser_tree` and `browser_tree_id_to_unit_path`
## tree buttons get ids corresponding to indexes in that array
func _load_units_dir_recursive(dir : DirAccess, parent : TreeItem):
	for file in dir.get_files():
		var file_in_the_tree = unit_browser_tree.create_item(parent)
		file_in_the_tree.set_text(0, file)
		file_in_the_tree.add_button( \
				0, open_button_texture, next_unit_id, false, "tooltip")

		browser_tree_id_to_unit_path[next_unit_id] = \
				dir.get_current_dir() + "/" + file
		#print("loaded ", browser_tree_id_to_unit_path[next_unit_id], \
				#" on id ", next_unit_id)

		next_unit_id += 1

	for child_directory in dir.get_directories():
		var directory_in_the_tree = unit_browser_tree.create_item(parent)
		directory_in_the_tree.set_text(0, child_directory)
		directory_in_the_tree.set_custom_bg_color(0, Color.DARK_BLUE)
		directory_in_the_tree.set_selectable(0, false)

		var child_dir_access = DirAccess.open( \
				dir.get_current_dir()+"/"+child_directory)
		_load_units_dir_recursive(child_dir_access, directory_in_the_tree)


## load unit when clicking open button
func _on_browser_open_button_clicked(_item, _column, id:int, _mouse_button):
	load_unit(browser_tree_id_to_unit_path[id])


## load unit when double clicking or pressing enter
func _on_browser_item_activated():
	var selected = unit_browser_tree.get_selected()
	var open_button_id = selected.get_button_id(0, 0)
	load_unit(browser_tree_id_to_unit_path[open_button_id])

## Sets DataUnit on specified path as `edited_unit`
## Updates `unit_preview_form`, `symbol_pickers`, `currently_edited_label` etc
func load_unit(path : String):
	var data = load(path)
	edited_unit = data as DataUnit
	dirty_changes = edited_unit.duplicate()

	currently_edited_label.text = edited_unit.resource_path

	unit_preview_form.apply_graphics(dirty_changes, CFG.NEUTRAL_COLOR)
	for dir in range(6):
		_set_symbol_picker(dir, dirty_changes.symbols[dir])


## chooses specified symbol on a specified picker
func _set_symbol_picker(dir: int, value: DataSymbol):
	var symbol_idx = all_data_symbols.find(value)
	symbol_pickers[dir].select(symbol_idx)


## updates `unit_preview_form` when symbol is picked
func on_symbol_selected(dir : int, picker_index : int):
	var picked_symbol = all_data_symbols[picker_index]
	print("selected dir %d %s - symbol %s - %s" % \
			[dir, GenericHexGrid.direction_to_name(dir as GenericHexGrid.GridDirections), \
			picked_symbol.type, E.symbol_to_name(picked_symbol.type)])

	unit_preview_form._apply_symbol_sprite(dir, picked_symbol.texture_path)
	dirty_changes.symbols[dir] = picked_symbol


## shows art picking dialog
func _on_pick_art_button_pressed():
	$PickArtDialog.show()


## applies new art to `unit_preview_form`
func _on_pick_art_dialog_file_selected(path):
	dirty_changes.texture_path = path
	unit_preview_form._apply_unit_texture(load(path))


## applies changes in `unit_preview_form` to `edited_unit` resource
func _on_save_pressed():
	if edited_unit == null or edited_unit.resource_path.is_empty():
		push_error("can only edit existing units, open a unit first")
		return
	edited_unit.texture_path = dirty_changes.texture_path
	for i in range(6):
		edited_unit.symbols[i] = dirty_changes.symbols[i]
	ResourceSaver.save(edited_unit, edited_unit.resource_path)
	# WARNING clears uids
	# see https://github.com/godotengine/godot/issues/83259
	# use uid_fixer script to fix


## return to main menu
func _on_back_button_pressed():
	hide()
	IM.go_to_main_menu()
