extends CanvasLayer

@export var  unitToTest : DataUnit

@onready var unit: AUnit = $Unit

var current_unit_path : String = ""

@onready var tree : Tree = $Tree

@onready var buttonTex:Texture2D = load("res://Art/old/push.png")

@onready var symbolPickers : Array[OptionButton] = [
	$ChangeW,
	$ChangeNW,
	$ChangeNE,
	$ChangeE,
	$ChangeSE,
	$ChangeSW,
]
var symbolTypes : Array[DataSymbol] = []

var next_unit_id:int = 0
var next_symbol_id:int = 0

var id_to_path: Dictionary = {}

func _ready():
	load_symbols()
	var direction = 0
	for s in symbolPickers:
		fill_symbol_picker(s)
		s.item_selected.connect(
			func onSelected(_index):
				on_symbol_selected(direction,_index)
		)
		direction += 1
	load_units()

func load_symbols():
	var path = "res://Resources/Battle/Symbols/"
	var dir = DirAccess.open(path)
	for f in dir.get_files():
		symbolTypes.append(load(path+f) as DataSymbol)

func fill_symbol_picker(s:OptionButton):
	for t in symbolTypes:
		s.add_item(E.Symbols.keys()[t.type])

func load_units():
	var image = buttonTex.get_image()
	image.resize(32, 32)
	buttonTex = ImageTexture.create_from_image(image)
	tree.button_clicked.connect(on_button)
	var root = tree.create_item()
	tree.hide_root = true
	var PATH = "res://Resources/Battle/Units/"
	var dir = DirAccess.open(PATH)
	if dir:
		load_units_dir(dir, root);
	else:
		print("Error opening folder:", PATH)

func load_units_dir(dir : DirAccess, parent : TreeItem):
	for file in dir.get_files():
		var child = tree.create_item(parent)
		child.set_text(0, file)
		child.add_button(0,buttonTex,next_unit_id,false,"tooltip")
		id_to_path[next_unit_id] = dir.get_current_dir()+"/"+file
		next_unit_id+=1
	for childDir in dir.get_directories():
		var child = tree.create_item(parent)
		child.set_text(0, childDir)
		load_units_dir(DirAccess.open(dir.get_current_dir()+"/"+childDir), child)

func on_button(_tree_item, _column, id:int, _mouse_button):
	load_unit(id_to_path[id])

func load_unit(path:String):
	current_unit_path = path
	#print(current_unit_path)
	$UnitName.text = current_unit_path
	var data = load(current_unit_path) as DataUnit
	unit.unitStats = data
	unit.get_node("sprite_unit").texture = load(data.texture_path)
	for dir in range(0,6):
		#unit.get_node("Symbols").get_children()[dir]\
			#.get_child(0).get_child(0).texture = \
			#load(symbolTypes[dir].texture_path)
		var symbolIdx = symbolTypes.find(data.symbols[dir])
		symbolPickers[dir].select(symbolIdx)
		on_symbol_selected(dir, symbolIdx)

func _on_pick_art_button_pressed():
	$PickArtDialog.show()

func _on_pick_art_dialog_file_selected(path):
	unit.unitStats.texture_path = path
	unit.get_node("sprite_unit").texture = load(path)

func on_symbol_selected(dir:int, id : int):
	#print("Dir ",dir," Symbol ",id)
	unit.unitStats.symbols[dir] = symbolTypes[id]
	if symbolTypes[id].texture_path == null:
		unit.get_node("Symbols").get_children()[dir]\
		.get_child(0).get_child(0).texture = null
		return
	unit.get_node("Symbols").get_children()[dir]\
		.get_child(0).get_child(0).texture = \
		load(symbolTypes[id].texture_path)

func _on_save_pressed():
	ResourceSaver.save(unit.unitStats, current_unit_path)
