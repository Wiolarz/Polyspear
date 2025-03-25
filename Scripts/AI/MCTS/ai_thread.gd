class_name AIThread
extends Node


var bm : BattleManagerFast
var mcts : BattleMCTSManager

# Can be safely written to
var reward_per_visit_dither : float

var _iterations_left : int

var _thread := Thread.new()
#var _thread_mutex := Mutex.new()

# These two variables are not using a mutex. Ideally they should, but it caused deadlock issues.
# Removed it for now, as they are only set from one place and read from the other so it shouldn't really cause serious issues.
# potentially TODO (i wish godot had atomic variables so i could sleep well)
# (or maybe even implement them in LibSpear iiiddkk)
var _running := true 


const ITERATIONS_QUANT = 1000
const ITERATIONS_INF = 1000000000

signal complete()
signal iteration_quant_finished(move_scores: Dictionary)

## Create a new AI thread from BattleGridState, BattleMCTSManager
static func from(
		bgs_ : BattleGridState, 
		mcts_ : BattleMCTSManager, 
		iterations_ : int = ITERATIONS_INF
		) -> AIThread:
	var new := AIThread.new()
	
	new._iterations_left = iterations_
	new.bm = BattleManagerFast.from(bgs_)
	new.add_child(new.bm)
	
	new.mcts = mcts_
	new.mcts.set_root(new.bm)
	new.add_child(new.mcts)
	
	return new


func start():
	_thread.start(_thread_process)


func _thread_process():
	while true:
		
		var iterations : int = min(_iterations_left, ITERATIONS_QUANT)
		if iterations == 0:
			(func(): complete.emit()).call_deferred()
			break
		
		mcts.iterate(iterations)
		_iterations_left -= iterations
		
		var move_scores := {}
		var move_scores_cpp := mcts.get_move_scores()
		for i in move_scores_cpp:
			move_scores[bm.libspear_tuple_to_move_info(i)] = move_scores_cpp[i]
		
		(func(): iteration_quant_finished.emit(move_scores)).call_deferred()
		
		var running = _running
		if not running:
			break
	
	(func(): print("ai thread shutdown")).call_deferred()
	queue_free.call_deferred()


## Shutdown the thread gracefully and queue_free the object when it's done
func destroy():
	_running = false # will call queue_free from worker thread
	if _thread.is_alive():
		print("waiiiring")
		#_thread.wait_to_finish()


func _exit_tree():
	destroy()
