extends Panel

@onready var button_columns : Array[VBoxContainer] = [ \
	$Margin/VBoxContainer/HBoxContainer/Scroll/VBox/HBoxContainer/Column1,
	$Margin/VBoxContainer/HBoxContainer/Scroll/VBox/HBoxContainer/Column2,
	$Margin/VBoxContainer/HBoxContainer/Scroll/VBox/HBoxContainer/Column3]


func _ready():
	generate_data_symbol_buttons()


func generate_data_symbol_buttons() -> void:
	# clean mockup ui
	for column in button_columns:
		for mock_button in column.get_children():
			mock_button.queue_free()

	var path = CFG.SYMBOLS_PATH
	var dir = DirAccess.open(path)
	var symbol_idx : int = -1
	for data_symbol_file_path in dir.get_files():
		symbol_idx += 1
		var data_symbol : DataSymbol = load(path + data_symbol_file_path)

		var button : TextureButton = load("res://Scenes/UI/Wiki/wiki_symbol_button.tscn").instantiate()

		button_columns[symbol_idx % button_columns.size()].add_child(button)
