class_name Player
extends Node

var alive = true

var player_name : String = ""

var player_type : E.player_type = E.player_type.OBSERVER

var bot_engine : AIInteface

var faction : Faction

# Player resources
var wood : int = 0
var iron : int = 0
var ruby : int = 0


var cities : Array[City] = []
var heroes : Array[Hero] = []

func _ready():
	name = "Player > " + player_name

func use_bot(bot_enabled:bool):
	if bot_enabled == (bot_engine != null):
		return
	if not bot_enabled:
		remove_child(bot_engine)
		bot_engine = null
	else:
		bot_engine = ExampleBot.new(self)
		add_child(bot_engine)

func your_turn():
	#UI stuff to let player know its his turn,
	# in case play is AI, call his decision maker
	

	if bot_engine != null:
		bot_engine.play_move()
	
	print("your move " + player_name)
