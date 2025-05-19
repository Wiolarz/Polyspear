extends HBoxContainer


const UNIT_ICON_SIZE : float = 100.0

@onready var units_box_first_row : BoxContainer = $Units/FirstRow
@onready var units_box_second_row : BoxContainer = $Units/SecondRow


func load_army(army : Army):

	# city garrison allows player to enter it, even though there is no hero in second army
	if not army.hero:
		var city : City = WS.get_city_at(army.coord)
		if city:
			$HeroIcon.texture = load(WS.grid.get_hex(city.coord).data_tile.texture_path)
			$ArmyLabel.text = "City Garrison"
		else:  # Neutral camp/ outpost garrison
			assert(army.units_data.size() > 0, "There shouldn't exist empty neutral army/outpost garrison")
			$HeroIcon.texture = load(army.units_data[0].texture_path)
			$ArmyLabel.text = "Neutral Army"

	else:
		$ArmyLabel.text = army.hero.hero_name
		$HeroIcon.texture = load(army.hero.data_unit.texture_path)


	# clean unit icons from rows
	for old_icon in units_box_first_row.get_children():
		old_icon.queue_free()
	for old_icon in units_box_second_row.get_children():
		old_icon.queue_free()

	var	bg_color : DataPlayerColor = army.controller.get_player_color()


	var added_icon_idx : int = -1

	for unit : DataUnit in army.units_data:
		added_icon_idx += 1
		# Generating unit buttons

		var unit_icon := TextureRect.new()
		unit_icon.texture = preload("res://Art/items/hex_border_light.png")
		unit_icon.custom_minimum_size = Vector2.ONE * UNIT_ICON_SIZE
		unit_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		unit_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


		var unit_display := UnitForm.create_for_summon_ui(unit, bg_color)
		unit_display.position = unit_icon.texture.get_size()/2
		var center_container = CenterContainer.new()
		unit_icon.add_child(center_container)
		center_container.add_child(unit_display)
		center_container.set_anchors_preset(Control.LayoutPreset.PRESET_CENTER)
		center_container.name = "Center"
		unit_display.name = "UnitForm"
		unit_display.position = Vector2.ZERO

		# TEMP need to find out good way to calculate scale, the constant number
		# here was find empirically
		var calculated_scale = 0.00058 * UNIT_ICON_SIZE
		unit_display.scale = Vector2.ONE * calculated_scale

		if added_icon_idx % 2 == 0:
			units_box_first_row.add_child(unit_icon)
		else:
			units_box_second_row.add_child(unit_icon)


	var empty_slot := TextureRect.new()
	empty_slot.texture = preload("res://Art/items/hex_border_light.png")
	empty_slot.custom_minimum_size = Vector2.ONE * UNIT_ICON_SIZE
	empty_slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	empty_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


	for i in range(army.max_army_size - army.units_data.size()):
		empty_slot = empty_slot.duplicate()
		if added_icon_idx % 2 == 0:
			units_box_first_row.add_child(empty_slot)
		else:
			units_box_second_row.add_child(empty_slot)
