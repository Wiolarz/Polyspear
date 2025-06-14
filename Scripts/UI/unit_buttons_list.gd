class_name UnitsButtonsList
extends BoxContainer

signal unit_was_selected()

## used only for placement unit tiles, points to currently selected unit/unit-button in placement
## bar
var selected_unit_pointer : DataUnit = null
var _selected_unit_button_pointer : BaseButton = null


## used only for placement unit tiles, points to currently hovered unit button in placement bar
## (same set of buttons as _`selected_unit_button_pointer` points to
var _hovered_unit_button_pointer : BaseButton = null


func load_unit_buttons(army : Army, units_to_display : Array[DataUnit], containers : Array[BoxContainer],
						unit_button_size : float = 100.0, fill_empty_slots : bool = false,
						is_clickable : bool = true) -> void:

	# clean unit icons from rows
	for container in containers:
		for old_button in container.get_children():
			old_button.queue_free()

	var bg_color : DataPlayerColor

	if army.controller:
		bg_color = army.controller.get_player_color()
	else:
		bg_color = CFG.NEUTRAL_COLOR


	var added_icon_idx : int = -1

	for unit : DataUnit in units_to_display:
		added_icon_idx += 1
		# Generating unit buttons

		var unit_display := UnitForm.create_for_summon_ui(unit, bg_color)

		var button
		if is_clickable:
			button = TextureButton.new()
			button.texture_normal = CFG.SUMMON_BUTTON_TEXTURE
			button.custom_minimum_size = Vector2.ONE * unit_button_size
			button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			button.ignore_texture_size = true
			unit_display.position = button.texture_normal.get_size()/2
		else:
			button = TextureRect.new()
			button.texture = preload("res://Art/items/hex_border_light.png")
			button.custom_minimum_size = Vector2.ONE * unit_button_size
			button.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			button.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			unit_display.position = button.texture.get_size()/2



		var center_container = CenterContainer.new()

		button.add_child(center_container)


		center_container.add_child(unit_display)
		center_container.set_anchors_preset(Control.LayoutPreset.PRESET_CENTER)
		center_container.name = "Center"
		unit_display.name = "UnitForm"
		unit_display.position = Vector2.ZERO



		# TEMP need to find out good way to calculate scale, the constant number
		# here was find empirically
		var calculated_scale = 0.00058 * unit_button_size
		unit_display.scale = Vector2.ONE * calculated_scale

		containers[added_icon_idx % containers.size()].add_child(button)



		if not is_clickable:
			continue

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



	if not fill_empty_slots:
		return

	var empty_slot := TextureRect.new()
	empty_slot.texture = preload("res://Art/items/hex_border_light.png")
	empty_slot.custom_minimum_size = Vector2.ONE * unit_button_size
	empty_slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	empty_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


	for i in range(army.max_army_size - army.units_data.size()):
		added_icon_idx += 1
		empty_slot = empty_slot.duplicate()
		containers[added_icon_idx % containers.size()].add_child(empty_slot)
