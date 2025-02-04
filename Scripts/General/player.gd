class_name Player
extends Node


var bot_engine : AIInterface

## occupier identifies who uses this slot [br]
## its an `int` or a `String` [br]
## `int` -> AI level eg. 1 [br]
## `String == ""` -> we (local player) [br]
## `String != ""` -> remote player with specified network name [br]
var occupier = ""


## used for some simpleness at player in world
var index : int = -1

var team : int = 0

var timer_reserve_sec : int = CFG.CHESS_CLOCK_BATTLE_TIME_PER_PLAYER_MS
var timer_increment_sec : int = CFG.CHESS_CLOCK_BATTLE_TURN_INCREMENT_MS


## World Gameplay
var race : DataRace = null
var faction : WorldPlayerState = null  # TEMP verify if its needed?

## for battle only mode
var units_list : Array[DataUnit] = [null,null,null,null,null] #TODO refactor to change variable to private as we have a clean getter for it
var slot_hero : DataHero = null

## index of color see `CFG.TEAM_COLORS`
var color_idx : int = 0




static func create(new_slot : Slot) -> Player:
	var result := Player.new()

	if new_slot.is_bot():
		assert(FileAccess.file_exists(new_slot.battle_bot_path), 
			   "File for bot '%s' does not exist" % [new_slot.battle_bot_path])
		result.bot_engine = load(new_slot.battle_bot_path).instantiate()
		assert(result.bot_engine != null, "Bot '%s' does not exist" % new_slot.battle_bot_path)
		result.add_child(result.bot_engine)
		result.bot_engine.set_player(result)


	result.name = "Player_" + result.get_player_name()

	return result


func _init(): #?
	name = "Player"


#region Getters

func is_local() -> bool:
	return occupier is String and occupier.is_empty()



func get_player_name() -> String:
	# TODO make these names same as elsewhere
	if bot_engine:
		return "AI"
	if is_local():
		return "LOCAL" # TODO use the same identifier which is "(( you ))" when
					   # offline
	# network login
	return occupier


func get_player_color() -> DataPlayerColor:
	return CFG.TEAM_COLORS[color_idx]


func get_faction() -> WorldPlayerState:
	# TODO store faction in state
	return faction

#endregion Getters


## let player know its his turn,
## in case play is AI, call his decision maker
func your_turn(battle_state : BattleGridState) -> void:
	var color_name = CFG.TEAM_COLORS[color_idx].name
	print("your move %s - %s" % [get_player_name(), color_name])

	if bot_engine and not NET.client: # AI is simulated on server only
		bot_engine.play_move(battle_state)


func get_occupier_name(all_slots : Array[Slot]) -> String:
	if bot_engine:
		return _get_bot_name(all_slots)
	if occupier == "":
		return NET.get_current_login()
	return occupier as String


func _get_bot_name(all_slots : Array[Slot]) -> String:
	var number_of_ais : int = 0
	var index_of_this_ai : int = 0
	for slot in all_slots:
		if slot.is_bot():
			if slot == self:
				index_of_this_ai = number_of_ais
			number_of_ais += 1
	if number_of_ais == 1:
		return "AI"
	return "AI %s" % index_of_this_ai



