class_name AIWorldBotRandom
extends AIWorldInterface


func choose_move() -> WorldMoveInfo:

	var goods_spending_moves : Array[WorldMoveInfo] = WS.get_all_goods_spending_moves()
	if goods_spending_moves.size() > 0:
		return goods_spending_moves[randi_range(0, goods_spending_moves.size() - 1)]

	var combat_destinations : Array[Vector2i] = WS.get_all_combat_destinations()

	var faction = WS.player_states[WS.current_player_index]
	for army in faction.hero_armies:
		if army.hero.movement_points == 0:
			continue
		if army.hero.travel_path.size() < 2:
			WM.ai_generate_path(army, combat_destinations[randi_range(0, combat_destinations.size() - 1)])
		if army.hero.travel_path.size() >= 2:
			var move := WorldMoveInfo.make_world_travel(army.coord, army.hero.travel_path[1])
			army.hero.travel_path.pop_front()
			
			return move


	return WorldMoveInfo.make_end_turn()
