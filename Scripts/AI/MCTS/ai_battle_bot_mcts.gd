class_name AIBattleBotMCTS
extends ExampleBot

@export var iterations = 10000

func play_move() -> void:
	
	var bm = BM.cloned_as_fast()
	var mcts = BattleMCTSManager.new()
	mcts.set_root(bm)
	
	mcts.iterate(iterations)
	var unit = mcts.get_optimal_move_unit(0)
	var position = mcts.get_optimal_move_position(0)
	
	print("MCTS best move: id ", unit, " -> ", position)
	
	# TODO actually use mcts instead of this
	super.play_move()
