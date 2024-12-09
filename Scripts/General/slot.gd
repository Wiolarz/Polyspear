class_name Slot extends Resource

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

var faction : DataFaction = null

## for battle only mode
var units_list : Array[DataUnit] = [null,null,null,null,null] #TODO refactor to change variable to private as we have a clean getter for it
var slot_hero : DataHero = null

## index of color see `CFG.TEAM_COLORS`
var color : int = 0



func _init():
	if CFG.player_options.use_default_AI_players:
		occupier = 0


func is_bot() -> bool:
	return occupier is int


func is_local() -> bool:
	return occupier.is_empty()


func set_units_length(value : int) -> void:
	units_list.resize(value)


## for "Custom battles" unit list creation
## ignores empty values in units_list
func get_units_list() -> Array[DataUnit]:
	var non_empty : Array[DataUnit] = []
	for unit in units_list:
		if not unit:
			continue
		non_empty.append(unit)
	return non_empty


## for replays
func set_units(new_units : Array[DataUnit]) -> void:
	for idx in range(units_list.size()):
		if idx >= new_units.size():
			units_list[idx] = null
			continue
		units_list[idx] = new_units[idx]


func get_occupier_name(all_slots: Array[Slot]) -> String:
	if is_bot():
		return _get_bot_name(all_slots)
	if occupier == "":
		return NET.get_current_login()
	return occupier as String


func _get_bot_name(all_slots: Array[Slot]) -> String:
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


func get_player_name() -> String:
	# TODO make these names same as elsewhere
	if is_bot():
		return "AI"
	if is_local():
		return "LOCAL" # TODO use the same identifier which is "(( you ))" when
					   # offline
	# network login
	return occupier
