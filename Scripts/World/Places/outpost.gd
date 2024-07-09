class_name Outpost
extends Place


var per_turn : Goods
var outpost_type : String
var neutral_army_preset : PresetArmy
var buildings : Array[DataBuilding] = []


static func create_new(args : PackedStringArray, coord : Vector2i) -> Place:

	var type = ""

	if args.size() != 1:
		push_error("outpost needs exactly one argument to create")

	var result = Outpost.new()
	type = args[0]
	match type:
		"wood":
			result.per_turn = Goods.new(1,0,0)
			result.neutral_army_preset = load(CFG.OUTPOST_WOOD_PATH)
		"iron":
			result.per_turn = Goods.new(0,1,0)
			result.neutral_army_preset = load(CFG.OUTPOST_IRON_PATH)
		"ruby":
			result.per_turn = Goods.new(0,0,1)
			result.neutral_army_preset = load(CFG.OUTPOST_RUBY_PATH)
		_:
			push_error("bad type of outpost")
			return null

	# TODO move this somewhere else -- this should not be here
	result.coord = coord
	result.movable = true
	result.outpost_type = type

	return result


func on_game_started():
	pass
	#WM.spawn_neutral_army(neutral_army, coord)


func get_army_at_start() -> PresetArmy:
	return neutral_army_preset


func interact(world_state : WorldState, army : Army) -> bool:
	return capture(world_state, army.controller_index)


func capture(world_state : WorldState, player_index : int) -> bool:
	var old_controller_index = controller_index
	if player_index == old_controller_index:
		return false # nothing to do
	var old_player = world_state.get_player(old_controller_index)
	var new_player = world_state.get_player(player_index)
	if old_player: # we need to take the outpost from old player first
		controller_index = -1
		old_player.outposts.remove(self)
		world_state._delete_outpost_upgrades_if_needed(old_controller_index)
	if new_player:
		controller_index = player_index
		new_player.outposts.append(self)
	return true


func on_end_of_turn(world_state : WorldState):
	var player : WorldPlayerState = world_state.get_player(controller_index)
	if player:
		player.goods.add(per_turn)


func get_map_description() -> String:
	return per_turn.to_string_short("empty")


func to_specific_serializable(dict : Dictionary) -> void:
	pass


func paste_specific_serializable_state(dict : Dictionary) -> void:
	buildings = []

	# var player = world_state.get_player(controller_index)
	# if player:
	# 	player.outposts.append(self)
