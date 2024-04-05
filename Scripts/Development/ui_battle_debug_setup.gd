extends CanvasLayer

const MAPS_PATH = "res://Resources/Battle/Battle_Maps/"
const UNITS_PATH = "res://Resources/Battle/Units/"
const PRESETS_PATH = "res://Resources/Tests/Battle_setups/"

@onready var mapsList : OptionButton = $MapsList
@onready var playerNames: Array[TextEdit] = [
	$PlayerName1,
	$PlayerName2,
]
@onready var unitsLists = [ # Array[Array[OptionButton]]
	[
		$UnitsList1_1,
		$UnitsList1_2,
		$UnitsList1_3,
		$UnitsList1_4,
		$UnitsList1_5,
	],
	[
		$UnitsList2_1,
		$UnitsList2_2,
		$UnitsList2_3,
		$UnitsList2_4,
		$UnitsList2_5,
	]
]


@onready var presetsList: OptionButton = $PresetsList
@export var default_battle_setup : BattleSetup
var  current_preset: BattleSetup

func _ready():
	_load_resource_lists()
	_load_preset(default_battle_setup)

func _load_resource_lists():
	for mapPath in TestTools.list_files_in_folder(MAPS_PATH, true):
		mapsList.add_item(mapPath)

	var unitPaths = TestTools.list_files_in_folder(UNITS_PATH, true, true);
	for army in unitsLists:
		for armySlot in army:
			armySlot.add_item("empty")
			for unitPath in unitPaths:
				armySlot.add_item(unitPath)
	
	for presetPath in TestTools.list_files_in_folder(PRESETS_PATH, true):
		presetsList.add_item(presetPath)

func _load_preset(preset : BattleSetup):
	current_preset = preset
	_clear_armies()
	for armyIdx in range(2):
		var army = preset.armies[armyIdx]
		var unitIdx = 0
		for unit in army.units:
			if _try_set_unit(unitsLists[armyIdx][unitIdx], unit.resource_path):
				unitIdx += 1
		playerNames[armyIdx].text = preset.player_settings[armyIdx].player_name

func _clear_armies():
	for army in unitsLists:
		for unit: OptionButton in army:
			unit.selected = 0

func _try_set_unit(unitsOption : OptionButton, path:String) -> bool:
	for idx in range(unitsOption.item_count):
		if unitsOption.get_item_text(idx) == path:
			unitsOption.select(idx)
			return true
	return false

func _on_start_button_pressed():
	var map = load(mapsList.get_item_text(mapsList.selected))
	var armies : Array[Army] = []
	IM.players = []
	IM.players.append(_create_player(playerNames[0].text))
	IM.players.append(_create_player(playerNames[1].text))
	armies.append(_create_army(_get_options_for_army(0), IM.players[0]))
	armies.append(_create_army(_get_options_for_army(1), IM.players[1]))
	BM.start_battle(armies, map)
	hide()

func _get_options_for_army(idx : int) -> Array[OptionButton]:
	var typedResult : Array[OptionButton] = []
	typedResult.assign(unitsLists[idx])
	return typedResult

func _on_save_button_pressed():
	current_preset.battle_map = load(mapsList.get_item_text(mapsList.selected))
	current_preset.armies = []
	for armyIdx in range(unitsLists.size()):
		var unitOptions = _get_options_for_army(armyIdx)
		var unitsData = _get_army_as_units_data(unitOptions)
		var armySet = ArmySet.from_units_data(unitsData)
		current_preset.armies.append(armySet)
	ResourceSaver.save(current_preset)

func _create_army(unitOptions : Array[OptionButton], controller : Player) -> Army:
	var result = Army.new()
	result.controller = controller
	result.units_data = _get_army_as_units_data(unitOptions)
	return result

func _get_army_as_units_data(unitOptions : Array[OptionButton]) -> Array[DataUnit]:
	var resultUntyped = unitOptions\
		.map(func getUnitData(option): return _get_unit_data(option))\
		.filter(func noNNulls(option): return option != null)
	var resultTyped: Array[DataUnit] = []
	resultTyped.assign(resultUntyped)
	return resultTyped

func _get_unit_data(option : OptionButton) -> DataUnit :
	var path = option.get_item_text(option.selected)
	if path == "empty": return null
	return load(path) 
	
func _create_player(playerName : String) -> Player:
	var result = Player.new()
	result.player_name = playerName
	return result


func _on_presets_list_item_selected(index):
	_load_preset( load(presetsList.get_item_text(index)))

