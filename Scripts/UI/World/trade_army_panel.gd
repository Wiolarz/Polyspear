extends VBoxContainer

signal unit_was_selected()

signal army_swap()

#TODO make two units columns to fit 9 units + hero on screen for each side


## used only for placement unit tiles, points to currently selected unit/unit-button in placement
## bar
var selected_unit_pointer : DataUnit = null
var _selected_unit_button_pointer : BaseButton = null

## used only for placement unit tiles, points to currently hovered unit button in placement bar
## (same set of buttons as _`selected_unit_button_pointer` points to
var _hovered_unit_button_pointer : BaseButton = null


const UNIT_BUTTON_SIZE : float = 130.0

@onready var units_box_first_column : BoxContainer = $Units/FirstColumn
@onready var units_box_second_column : BoxContainer = $Units/SecondColumn

var loaded_army : Army

func _ready() -> void:
	$HeroButton.pressed.connect(_attemp_army_swap)

func load_army(army : Army):
	loaded_army = army
	selected_unit_pointer = null
	_selected_unit_button_pointer = null

	# city garrison allows player to enter it, even though there is no hero in second army
	if not army.hero:
		var city : City = WS.get_city_at(army.coord)
		assert(city,
		"attempt to trade with an army without a hero, which isn't a city garrison")
		$HeroButton.texture_normal = load(WS.grid.get_hex(city.coord).data_tile.texture_path)
		$ArmyLabel.text = "City Garrison"
	else:
		$ArmyLabel.text = army.hero.hero_name
		$HeroButton.texture_normal = load(army.hero.data_unit.texture_path)


	# clean unit icons from rows
	for old_icon in units_box_first_column.get_children():
		old_icon.queue_free()
	for old_icon in units_box_second_column.get_children():
		old_icon.queue_free()

	var	bg_color : DataPlayerColor = army.controller.get_player_color()


	var added_icon_idx : int = -1

	for unit : DataUnit in army.units_data:
		added_icon_idx += 1
		# Generating unit buttons

		var button := TextureButton.new()
		button.texture_normal = CFG.SUMMON_BUTTON_TEXTURE
		button.custom_minimum_size = Vector2.ONE * UNIT_BUTTON_SIZE
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.ignore_texture_size = true

		var unit_display := UnitForm.create_for_summon_ui(unit, bg_color)
		unit_display.position = button.texture_normal.get_size()/2
		var center_container = CenterContainer.new()
		button.add_child(center_container)
		center_container.add_child(unit_display)
		center_container.set_anchors_preset(Control.LayoutPreset.PRESET_CENTER)
		center_container.name = "Center"
		unit_display.name = "UnitForm"
		unit_display.position = Vector2.ZERO

		# TEMP need to find out good way to calculate scale, the constant number
		# here was find empirically
		var calculated_scale = 0.00058 * UNIT_BUTTON_SIZE
		unit_display.scale = Vector2.ONE * calculated_scale


		if added_icon_idx % 2 == 0:
			units_box_first_column.add_child(button)
		else:
			units_box_second_column.add_child(button)


		var lambda = func on_click():
			# TODO for later: move these lambdas outside to increase readability
			if not army.controller.is_local():  # block multiplayer input
				return
			if _selected_unit_button_pointer:  # Deselects previously selected unit
				_selected_unit_button_pointer.get_node("Center/UnitForm").set_selected(false)

			if _selected_unit_button_pointer == button: # Selecting the same unit twice deselects it
				selected_unit_pointer = null
				_selected_unit_button_pointer = null
			else:
				selected_unit_pointer = unit
				_selected_unit_button_pointer = button
				_selected_unit_button_pointer.get_node("Center/UnitForm").set_selected(true)
				unit_was_selected.emit()

		button.pressed.connect(lambda)

		var lambda_hover = func(is_hovered : bool):
			# TODO for later: move these lambdas outside to increase readability
			if _hovered_unit_button_pointer:
				_hovered_unit_button_pointer.get_node("Center/UnitForm").set_hovered(false)

			if is_hovered:
				_hovered_unit_button_pointer = button
				_hovered_unit_button_pointer.get_node("Center/UnitForm").set_hovered(true)
			else:
				_hovered_unit_button_pointer = null
		button.mouse_entered.connect(lambda_hover.bind(true))
		button.mouse_exited.connect(lambda_hover.bind(false))


	var empty_slot := TextureRect.new()
	empty_slot.texture = preload("res://Art/items/hex_border_light.png")
	empty_slot.custom_minimum_size = Vector2.ONE * UNIT_BUTTON_SIZE
	empty_slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	empty_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


	for i in range(army.max_army_size - army.units_data.size()):
		added_icon_idx += 1
		empty_slot = empty_slot.duplicate()
		if added_icon_idx % 2 == 0:
			units_box_first_column.add_child(empty_slot)
		else:
			units_box_second_column.add_child(empty_slot)


func transfered_unit():
	loaded_army.leader_unit_changed.emit()

	selected_unit_pointer = null
	_selected_unit_button_pointer = null
	load_army(loaded_army)


func _attemp_army_swap() -> void:
	army_swap.emit()
