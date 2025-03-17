class_name AIThread
extends Node


var bm : BattleManagerFast
var mcts : BattleMCTSManager

# Can be safely read
var move_scores : Dictionary
var optimal_move : Array

# Can be safely written to
var reward_per_visit_dither : float

var quant_processed_sem := Semaphore.new()

var _iterations_left : int

var _thread := Thread.new()
var _thread_mutex := Mutex.new()
var _running := true
var _running_mutex := Mutex.new()

var _wait_on_quant_processed : bool


const ITERATIONS_QUANT = 1000
const ITERATIONS_INF = 1000000000

signal complete()
signal iteration_quant_finished()


static func from(
		bgs_ : BattleGridState, 
		mcts_ : BattleMCTSManager, 
		iterations_ : int = ITERATIONS_INF,
		wait_until_quant_processed : bool = true
		) -> AIThread:
	var new := AIThread.new()
	
	new._iterations_left = iterations_
	new.bm = BattleManagerFast.from(bgs_)
	new.add_child(new.bm)
	
	new.mcts = mcts_
	new.mcts.set_root(new.bm)
	new.add_child(new.mcts)
	
	new._wait_on_quant_processed = wait_until_quant_processed
	
	return new


func start():
	_thread.start(_thread_process)


func lock():
	_thread_mutex.lock()


func unlock():
	_thread_mutex.unlock()


func _thread_process():
	while true:
		
		var iterations : int = min(_iterations_left, ITERATIONS_QUANT)
		if iterations == 0:
			(func(): complete.emit()).call_deferred()
			#unlock()
			break
		
		mcts.iterate(iterations)
		_iterations_left -= iterations
		(func(): iteration_quant_finished.emit()).call_deferred()
		
		lock()
		move_scores = mcts.get_move_scores()
		optimal_move = mcts.get_optimal_move(reward_per_visit_dither)
		unlock()
		
		if _wait_on_quant_processed:
			quant_processed_sem.wait()
		
		# no such thing as not enough mutexes
		_running_mutex.lock()
		var running = _running
		_running_mutex.unlock()
		
		if not running:
			break
	
	(func(): print("ai thread shutdown")).call_deferred()
	#queue_free.call_deferred()


## Shutdown the thread gracefully and queue_free the object when it's done
func destroy():
	_running_mutex.lock()
	_running = false # will call queue_free from worker thread
	_wait_on_quant_processed = false
	_running_mutex.unlock()
	quant_processed_sem.post() # make sure the thread doesn't wait on exit


func _exit_tree():
	destroy()
	_thread.wait_to_finish()
