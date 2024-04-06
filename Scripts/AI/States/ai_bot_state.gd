"""
Parent class of AI States

All childs have to implement:
make_move(legal_moves)

"""
class_name AiBotState

extends Node

@export var tags : Array[ExampleBot.TAG] = []

var me:Player

func _init(my_tags : Array[ExampleBot.TAG], my_player:Player):
	tags = my_tags
	name = "AiBotState" + str(my_tags)
	me = my_player

func choose_move(legal_moves : Array[MoveInfo]) -> MoveInfo:
	var kill_moves = AIHelpers.get_all_kill_moves(legal_moves, me)
	if kill_moves.size() > 0:
		return kill_moves[randi_range(0, kill_moves.size() - 1)]
	return legal_moves[randi_range(0, legal_moves.size() - 1)]

