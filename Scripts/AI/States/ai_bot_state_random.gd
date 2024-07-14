class_name AiBotStateRandom
extends AiBotState


func _init(my_tags : Array[ExampleBot.TAG], my_player:Player ):
	tags = my_tags
	name = "AiBotStateRandom" + str(my_tags)
	me = my_player


func choose_move(battle_state : BattleGridState) -> MoveInfo:
	return AiBotStateRandom.choose_move_static(battle_state)


static func choose_move_static(battle_state : BattleGridState) -> MoveInfo:
	var moves = battle_state.get_possible_moves()
	assert(moves.size() > 0, "choose_move called with no moves to make")

	var kill_moves = battle_state.filter_only_kill_moves(moves)
	if kill_moves.size() > 0:
		return kill_moves[randi_range(0, kill_moves.size() - 1)]
	return moves[randi_range(0, moves.size() - 1)]
