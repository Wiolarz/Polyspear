"""
All childs have to implement:


"""


extends Node

class_name State

@export var GridManager : HexGridManager

@export var GM : GameplayManager


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

