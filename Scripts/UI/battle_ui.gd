class_name BattleUI
extends CanvasLayer

@onready var players_box : BoxContainer = $Players

@onready var units_box : BoxContainer = $Units

@onready var camera_button : Button = $SwitchCamera

var armies : Array[Army] = []

var selected_unit : DataUnit = null
var selected_button: TextureButton = null
var selected_unit_army_idx : int = -1

var current_player : Player = null

func _ready():
	pass

func get_army(player: Player) -> Army:
	var currentArmy = armies.filter(
		func controlledBy(a : Army):
			return a.controller == player
			)
	assert(currentArmy.size() == 1)
	return currentArmy[0]

func on_player_selected(selectedPlayer : Player, preview : bool = false):
	if not preview:
		current_player = selectedPlayer
	for i in range(armies.size()):
		var c = Color.WHITE if armies[i].controller != current_player else Color.RED
		players_box.get_child(i + 1).modulate = c

	# clean bottom row
	for old_buttons in units_box.get_children():
		old_buttons.queue_free()

	var army = get_army(selectedPlayer)
	for unitId : int in range(0, army.units_data.size()):
		var unit : DataUnit = army.units_data[unitId]
		var b = TextureButton.new()
		b.texture_normal = CFG.SUMMON_BUTTON_TEXTURE
		var unit_scene : UnitForm = CFG.UNIT_FORM_SCENE.instantiate()
		unit_scene.position = b.texture_normal.get_size()/2
		unit_scene.apply_template(unit)
		b.add_child(unit_scene)
		units_box.add_child(b)
		var lambda = func on_click():
			if (current_player != army.controller):
				return
			if (selected_button != null):
				selected_button.modulate = Color.WHITE
			selected_unit = unit
			selected_button = b
			selected_unit_army_idx = unitId
			b.modulate = Color.RED
		b.pressed.connect(lambda)

func _copy(army_list : Array[Army]):
	var result : Array[Army] = []
	for a in army_list:
		var aCopy = Army.new()
		aCopy.controller = a.controller
		aCopy.units_data = a.units_data.duplicate()
		result.append(aCopy)
	return result

func load_armies(army_list : Array[Army]):
	camera_button.disabled = IM.game_setup_info.game_mode != GameSetupInfo.GameMode.WORLD
	# save armies
	armies = _copy(army_list)

	# removing temp shit
	var players = players_box.get_children()
	players[2].queue_free()
	players[1].queue_free()

	units_box.show()

	for army in army_list:
		# create player buttons
		var n = Button.new()
		n.text = "Player " + army.controller.player_name
		n.pressed.connect(func p1(): on_player_selected(army.controller, true))
		players_box.add_child(n)

func unit_summoned(summon_phase_end : bool, unit : DataUnit):
	var army = get_army(current_player)
	# for AI
	if selected_unit_army_idx == -1:
		selected_unit_army_idx = army.units_data.find(unit)
	army.units_data.remove_at(selected_unit_army_idx)
	selected_unit = null
	selected_button = null
	selected_unit_army_idx = -1
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

