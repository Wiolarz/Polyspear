class_name BattleUI
extends CanvasLayer

@onready var players_box : BoxContainer = $Players

@onready var units_box : BoxContainer = $Units

@onready var camera_button : Button = $SwitchCamera

var armies_reference : Array[BM.ArmyInBattleState]

var selected_unit : DataUnit = null
var selected_unit_button : TextureButton = null
var current_player : int = 0


func _ready():
	pass


func load_armies(army_list : Array[BM.ArmyInBattleState]):
	camera_button.disabled = IM.game_setup_info.game_mode != GameSetupInfo.GameMode.WORLD

	# save armies
	armies_reference = army_list

	# removing temp shit
	var players = players_box.get_children()
	players[2].queue_free()
	players[1].queue_free()

	units_box.show()

	var idx = 0
	for army in army_list:
		var controller = army.army_reference.controller
		# create player buttons
		var n = Button.new()
		if controller:
			n.text = "Player " + controller.player_name
		else:
			n.text = "Player Neutral" #TEMP
		n.pressed.connect(func select(): on_player_selected(idx, true))
		players_box.add_child(n)
		idx += 1


func start_player_turn(army_index : int):
	on_player_selected(army_index, false)


func on_player_selected(army_index : int, preview : bool = false):
	selected_unit = null
	selected_unit_button = null

	if not preview:
		current_player = army_index

	for i in range(armies_reference.size()):
		var c = Color.WHITE if i != current_player else Color.RED
		players_box.get_child(i + 1).modulate = c

	# clean bottom row
	for old_buttons in units_box.get_children():
		old_buttons.queue_free()

	for unit in armies_reference[army_index].units_to_summon:
		var b = TextureButton.new()
		b.texture_normal = CFG.SUMMON_BUTTON_TEXTURE
		var unit_scene : UnitForm = CFG.UNIT_FORM_SCENE.instantiate()
		unit_scene.position = b.texture_normal.get_size()/2
		unit_scene.apply_template(unit)
		b.add_child(unit_scene)
		units_box.add_child(b)
		var lambda = func on_click():
			if (current_player != army_index):
				return
			if selected_unit_button:
				selected_unit_button.modulate = Color.WHITE
			selected_unit = unit
			selected_unit_button = b
			selected_unit_button.modulate = Color.RED
		b.pressed.connect(lambda)


func unit_summoned(summon_phase_end : bool, _unit : DataUnit):
	selected_unit = null
	selected_unit_button = null

	if summon_phase_end:
		units_box.hide()



func _on_switch_camera_pressed():
	IM.switch_camera()
	if IM.current_camera_position == E.CameraPosition.WORLD:
		camera_button.text = "Show Battle"
	else :
		camera_button.text = "Show World"


func _on_menu_pressed():
	IM.show_in_game_menu()

