class_name AiWorldBotRandom
extends AIWorldInterface


func choose_move() -> WorldMoveInfo:

	var goods_spending_moves : Array[WorldMoveInfo] = WS.get_all_goods_spending_moves()
	if goods_spending_moves.size() > 0:
		return goods_spending_moves[randi_range(0, goods_spending_moves.size() - 1)]



	return WorldMoveInfo.make_end_turn()

