"""
Parent class of AI States

All childs have to implement:
make_move(legal_moves)

"""
class_name State

extends Node




enum TAG \
{
	IDLE,
	ATTACK,
	DEFEND,
}
	
@export var tags : Array[TAG] = []

@export var StartingState : bool = false
	


func make_move(legal_moves):
	return legal_moves[randi_range(0, legal_moves.size() - 1)]

