class_name AIBattleBotMCTS
extends ExampleBot

@export var iterations = 30000

func play_move() -> void:
	
	var unit_array = []
	var bm = BM.cloned_as_fast(unit_array)
	var mcts = BattleMCTSManager.new()
	mcts.set_root(bm)
	
	mcts.iterate(iterations)
	var unit = mcts.get_optimal_move_unit(0)
	var position = mcts.get_optimal_move_position(0)
	
	print("MCTS best move: id ", unit, " -> ", position)
	
	var move: MoveInfo
	
	if unit_array[unit] is DataUnit: # Summon
		move = MoveInfo.make_summon(unit_array[unit], position)
	else: # Move
		move = MoveInfo.make_move(unit_array[unit].coord, position)
	
	await ai_thinking_delay()
	BM.perform_ai_move( move )
