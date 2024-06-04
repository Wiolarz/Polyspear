extends Resource
class_name SerializableBattleState

@export var replay : BattleReplay


func valid() -> bool:
	return replay != null


static func get_network_serialized(battle_state : SerializableBattleState) \
		-> PackedByteArray:
	var dict : Dictionary = {}
	var breplay = battle_state.replay
	if breplay:
		dict["moves"] = []
		var moves = dict["moves"]
		for move in breplay.moves:
			# HACK FIXME get rid of it and do it pretty
			var hacked_move = MakeMoveCommand.create_packet(move)
			moves.append(hacked_move)
	return var_to_bytes(dict)


static func from_network_serialized(ser : PackedByteArray) \
		-> SerializableBattleState:
	var result = SerializableBattleState.new()
	var dict : Dictionary = bytes_to_var(ser)

	# replay
	if \
			"moves" in dict and dict["moves"] is Array and \
			true:
		var breplay = BattleReplay.new()
		breplay.timestamp = Time.get_datetime_string_from_system()
		# TODO maybe use create
		var moves = dict["moves"]
		for move in moves:
			# HACK again
			var hacked_move : MoveInfo = MakeMoveCommand.create_from(move)
			breplay.moves.append(hacked_move)

		result.replay = breplay

	return result
