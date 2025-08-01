class_name BattlePlayerSlotPanel
extends PlayerSlotPanel


const EMPTY_UNIT_TEXT = " - empty - "


var unit_paths : Array[String]

var hero_paths : Array[String]

@onready var buttons_units : Array[OptionButton] = [
	$GeneralVContainer/OptionButtonUnit1,
	$GeneralVContainer/OptionButtonUnit2,
	$GeneralVContainer/OptionButtonUnit3,
	$GeneralVContainer/OptionButtonUnit4,
	$GeneralVContainer/OptionButtonUnit5,
]

@onready var hero_list : OptionButton = $GeneralVContainer/TopBarHContainer/OptionButtonHero


func _ready():
	button_battle_bot = get_node("GeneralVContainer/TopBarHContainer/OptionButtonBot")


	hero_paths = FileSystemHelpers.list_files_in_folder(CFG.HEROES_PATH, true, true)
	init_hero_list(hero_list)

	unit_paths = FileSystemHelpers.list_files_in_folder(CFG.UNITS_PATH, true, true)
	for index in buttons_units.size():
		var button : OptionButton = buttons_units[index]
		init_unit_button(button, index)

	super()



func init_unit_button(button : OptionButton, index : int):
	button.clear()
	button.add_item(EMPTY_UNIT_TEXT)
	for unit_path in unit_paths:
		button.add_item(unit_path.trim_prefix(CFG.UNITS_PATH))
	button.item_selected.connect(unit_in_army_changed.bind(index))


func init_hero_list(button : OptionButton) -> void:
	button.clear() #XD
	button.add_item(EMPTY_UNIT_TEXT)
	for hero_path in hero_paths:
		button.add_item(hero_path.trim_prefix(CFG.HEROES_PATH))
	button.item_selected.connect(hero_in_army_changed.bind())


func hero_in_army_changed(hero_index) -> void:
	var hero_path = hero_list.get_item_text(hero_index)
	var hero_data : DataHero = null
	if hero_path != EMPTY_UNIT_TEXT:
		hero_data = load(CFG.HEROES_PATH+"/"+hero_path)
	var slot_index = setup_ui.slot_to_index(self)

	IM.game_setup_info.set_hero(slot_index, hero_data)
	if NET.server:
		NET.server.broadcast_full_game_setup(IM.game_setup_info) #TODO add multi support
	if NET.client:
		pass#NET.client.queue_lobby_set_unit(slot_index, unit_index, unit_data) #TODO STUB


func unit_in_army_changed(selected_index, unit_index) -> void:
	var unit_path = buttons_units[unit_index].get_item_text(selected_index)
	var unit_data : DataUnit = null
	if unit_path != EMPTY_UNIT_TEXT:
		unit_data = load(CFG.UNITS_PATH+"/"+unit_path)
	var slot_index = setup_ui.slot_to_index(self)
	IM.game_setup_info.set_unit(slot_index, unit_index, unit_data)
	if NET.server:
		NET.server.broadcast_full_game_setup(IM.game_setup_info)
	if NET.client:
		NET.client.queue_lobby_set_unit(slot_index, unit_index, unit_data)


func set_army(units_list : Array[DataUnit]):
	while buttons_units.size() > units_list.size():
		var b = buttons_units.pop_back()
		$GeneralVContainer.remove_child(b)
		b.queue_free()
	while buttons_units.size() < units_list.size():
		var b := OptionButton.new()
		init_unit_button(b, buttons_units.size())
		buttons_units.append(b)
		$GeneralVContainer.add_child(b)
		b.custom_minimum_size = Vector2(200, 0)

	for index in units_list.size():
		set_unit(buttons_units[index], units_list[index])


## Change text only after sele
func set_unit(unit_button : OptionButton, unit : DataUnit):
	if not unit:
		unit_button.select(0)
		return
	for idx in unit_button.item_count:
		if unit.resource_path.ends_with(unit_button.get_item_text(idx)):
			unit_button.select(idx)


func _on_button_level_up_pressed():
	if not should_react_to_changes():
		return
	UI.show_hero_level_up()
