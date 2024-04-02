class_name BattleUI
extends CanvasLayer

@onready var players_box : BoxContainer = $Players

@onready var units_box : BoxContainer = $Units

var armies : Array[Army] = []

func _ready():
	pass

func _process(delta):
	if BM.selected_unit != null:
		print(BM.selected_unit)


func on_player_selected(controller : Player):
	# clean bottom row
	for old_buttons in units_box.get_children():
		old_buttons.queue_free()
	

	var selected_armies = armies.filter(
		func controlled_by(a : Army):
			return a.controller == controller
			)
	assert(selected_armies.size() == 1)
	
	for army in selected_armies:
		for unit : DataUnit in army.units_data:
			var b = TextureButton.new()
			b.texture_normal = load(unit.texture_path)
			# idea to add unit scenes as buttons child to display unit symbols properly, then reparent them to battle manager once they are in the scene
			# b.add_child(load("res://Scenes/Units/elf/Archer.tscn").instantiate())
			units_box.add_child(b)



func _create_button(unit_data : String):
	var unit = load(unit_data)

	var new_button = TextureButton.new()

	new_button.texture_normal = ResourceLoader.load(unit.texture_path)

	units_box.add_child(new_button)
	var lambda = func on_click():
		print("test")
		BM.selected_unit = unit
	
	new_button.pressed.connect(lambda)  # self._button_pressed


func load_armies(army_list : Array[Army]):
	# save armies
	armies = army_list

	# removing temp shit
	var players = players_box.get_children()
	players[2].queue_free()
	players[1].queue_free()
	
	for army in army_list:
		# create player buttons
		var n = Button.new()
		n.text = "Player " + army.controller.player_name
		n.pressed.connect(func p1(): on_player_selected(army.controller))
		players_box.add_child(n)








func _on_switch_camera_pressed():
	IM.switch_camera()
