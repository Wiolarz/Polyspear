extends CanvasLayer


const MAPS_PATH = "res://Resources/Battle/Battle_Maps/"
const UNITS_PATH = "res://Resources/Battle/Units/"
const PRESETS_PATH = "res://Resources/Tests/Battle_setups/"


@export var default_battle_setup : BattleSetup

var current_preset: BattleSetup

@onready var maps_list : OptionButton = $MapsList
@onready var player_names: Array[TextEdit] = [
	$PlayerName1,
	$PlayerName2,
]
@onready var player_is_ai: Array[CheckBox] = [
	$IsAI1,
	$IsAI2,
]
@onready var units_lists = [ # Array[Array[OptionButton]]
	[
		$VBoxContainer1/UnitsList1_1,
		$VBoxContainer1/UnitsList1_2,
		$VBoxContainer1/UnitsList1_3,
		$VBoxContainer1/UnitsList1_4,
		$VBoxContainer1/UnitsList1_5,
	],
	[
		$VBoxContainer2/UnitsList2_1,
		$VBoxContainer2/UnitsList2_2,
		$VBoxContainer2/UnitsList2_3,
		$VBoxContainer2/UnitsList2_4,
		$VBoxContainer2/UnitsList2_5,
	]
]

@onready var presets_list: OptionButton = $PresetsList


#region Main methods

func _load_preset(preset : BattleSetup) -> void:
	current_preset = preset
	_clear_armies()
	for army_idx in range(2):
		var army = preset.armies[army_idx]
		var unit_idx = 0
		for unit in army.units:
			if _try_set_unit(units_lists[army_idx][unit_idx], unit.resource_path):
				unit_idx += 1
		player_names[army_idx].text = preset.player_settings[army_idx].player_name


func _clear_armies() -> void:
	for army in units_lists:
		for unit: OptionButton in army:
			unit.selected = 0


func _try_set_unit(units_option : OptionButton, path : String) -> bool:
	for idx in range(units_option.item_count):
		if units_option.get_item_text(idx) == path.trim_prefix(UNITS_PATH):
			units_option.select(idx)
			return true
	return false

#endregion


#region Buttons methods

func _create_army(unit_options : Array[OptionButton], controller : Player) -> Army:
	var result = Army.new()
	result.controller = controller
	result.units_data = _get_army_as_units_data(unit_options)
	return result


func _get_army_as_units_data(unit_options : Array[OptionButton]) -> Array[DataUnit]:
	var result_untyped = unit_options \
		.map(func getUnitData(option): return _get_unit_data(option))\
		.filter(func noNNulls(option): return option != null)
	var result_typed: Array[DataUnit] = []
	result_typed.assign(result_untyped)
	return result_typed


func _get_unit_data(option : OptionButton) -> DataUnit :
	var unit_name = option.get_item_text(option.selected)
	if unit_name == "empty": return null
	return load(UNITS_PATH + unit_name) 


func _create_player(player_name : String) -> Player:
	var result = Player.new()
	result.player_name = player_name
	return result


func _get_options_for_army(idx : int) -> Array[OptionButton]:
	var typed_result : Array[OptionButton] = []
	typed_result.assign(units_lists[idx])
	return typed_result

#endregion


#region Buttons

func _on_start_button_pressed() -> void:
	var map = load(maps_list.get_item_text(maps_list.selected))
	var armies : Array[Army] = []
	var players: Array[Player] = []
	for playerIdx in range(2):
		var player = _create_player(player_names[playerIdx].text)
		player.use_bot(player_is_ai[playerIdx].button_pressed)
		players.append(player)
		armies.append(_create_army(_get_options_for_army(playerIdx), player))
	IM.players = players
	BM.start_battle(armies, map)
	hide()


func _on_save_button_pressed() -> void:
	current_preset.battle_map = load(maps_list.get_item_text(maps_list.selected))
	current_preset.armies = []
	for army_idx in range(units_lists.size()):
		var unit_options = _get_options_for_army(army_idx)
		var units_data = _get_army_as_units_data(unit_options)
		var army_set = ArmySet.from_units_data(units_data)
		current_preset.armies.append(army_set)
	ResourceSaver.save(current_preset)


func _on_presets_list_item_selected(index) -> void:
	_load_preset(load(UNITS_PATH+presets_list.get_item_text(index)))



#endregion


#region Setup

func _load_resource_lists() -> void:
	for map_path in TestTools.list_files_in_folder(MAPS_PATH, true):
		maps_list.add_item(map_path)

	var unit_paths = TestTools.list_files_in_folder(UNITS_PATH, true, true);
	for army in units_lists:
		for army_slot in army:
			army_slot.add_item("empty")
			for unit_path in unit_paths:
				army_slot.add_item(unit_path.trim_prefix(UNITS_PATH))
	
	for preset_path in TestTools.list_files_in_folder(PRESETS_PATH, true):
		presets_list.add_item(preset_path)


func _ready():
	_load_resource_lists()
	_load_preset(default_battle_setup)

#endregion
