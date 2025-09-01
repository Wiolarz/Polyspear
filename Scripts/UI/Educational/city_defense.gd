extends Panel

@onready var ai_difficulty_selection : OptionButton = \
$MarginContainer/VBoxContainer/Columns/VBoxContainer/VBoxNewRunRules/HBoxAIDifficulty/AIDifficulty

@onready var starting_army : PresetArmy = load("res://Resources/Presets/City_Defense_Waves/undead_start_force.tres")
var attacker_waves : Array[PresetArmy] = []

@onready var units_purchases : HBoxContainer = $MarginContainer/VBoxContainer/Columns/VBoxContainer/HBoxPurchases


@onready var continue_button : Button = $MarginContainer/VBoxContainer/Columns/VBoxContainer/ContinueButton

@onready var current_run_information : Label = $MarginContainer/VBoxContainer/Columns/VBoxContainer/CurrentRunLabel

@onready var army_display : UnitsButtonsList = $MarginContainer/VBoxContainer/Columns/VBoxContainer/HBoxArmy


var is_run_ongoing : bool = false

var selected_bot_path : String

var current_wave : int = -1


var current_roster : PresetArmy


var player_goods : Goods



@onready var player_race : DataRace = CFG.RACE_UNDEAD


func _ready():
	##TODO add support for more starting armies and attacker types

	for wave_path in FileSystemHelpers.list_files_in_folder("res://Resources/Presets/City_Defense_Waves/orcs_waves/"):
		var full_wave_path : String = "res://Resources/Presets/City_Defense_Waves/orcs_waves/" + wave_path

		var attacker_army : PresetArmy = load(full_wave_path)
		print(full_wave_path)
		print(attacker_army.units.size())
		attacker_waves.append(attacker_army)

	var bot_paths = FileSystemHelpers.list_files_in_folder(CFG.BATTLE_BOTS_PATH, true, true)
	ai_difficulty_selection.clear()
	for bot_name in bot_paths:
		ai_difficulty_selection.add_item(bot_name.trim_prefix(CFG.BATTLE_BOTS_PATH))


func _refresh_unit_purchases() -> void:
	Helpers.remove_all_children(units_purchases)
	for unit in player_race.units_data:
		var unit_buy_button := Button.new()
		unit_buy_button.text = unit.unit_name
		unit_buy_button.text += "\n" + unit.cost.to_string_short("free")

		unit_buy_button.pressed.connect(_buy_unit.bind(unit))
		units_purchases.add_child(unit_buy_button)
		unit_buy_button.disabled = not player_goods.has_enough(unit.cost)


func _refresh_roster_display() -> void:
	army_display.simplified_display_load_army(current_roster)


func _buy_unit(unit : DataUnit) -> void:
	assert(player_goods.has_enough(unit.cost))
	player_goods.subtract(unit.cost)
	current_roster.units.append(unit)
	_refresh_roster_display()
	_refresh_unit_purchases()


func _launch_battle(enemy_wave : PresetArmy):
	current_wave += 1
	var battle := ScriptedBattle.new()
	battle.armies = [
		current_roster,
		enemy_wave
	]
	battle.battle_map = load("res://Resources/Battle/Battle_Maps/medium_varied.tres")

	IM.start_scripted_battle(battle, selected_bot_path, 0)


## after BM ends battle with IM.is_city_defense_active being true it calls IM which calls this
func battle_ended(armies : Array[BattleGridState.ArmyInBattleState]) -> void:
	if not armies[0].can_fight():  # player lost
		IM.is_city_defense_active = false
		is_run_ongoing = false
		continue_button.disabled = true
		return

	for dead_unit in armies[0].dead_units:
		current_roster.units.erase(dead_unit)

	player_goods.add(Goods.new(10, 5, 3))
	_refresh_unit_purchases()
	current_run_information.text = "Current Run: " + player_goods.to_string_short()
	_refresh_roster_display()


## Button
func start_new_run() -> void:
	is_run_ongoing = true
	current_wave = -1

	selected_bot_path =  CFG.BATTLE_BOTS_PATH + ai_difficulty_selection.get_item_text(ai_difficulty_selection.get_selected())

	current_roster = load("res://Resources/Presets/City_Defense_Waves/undead_start_force.tres")

	continue_button.disabled = false
	IM.is_city_defense_active = true


	player_goods = Goods.new(15, 10, 5)
	current_run_information.text = "Current Run: " + player_goods.to_string_short()

	_refresh_unit_purchases()
	_refresh_roster_display()


## Button
func continue_run() -> void:
	_launch_battle(attacker_waves[current_wave])
