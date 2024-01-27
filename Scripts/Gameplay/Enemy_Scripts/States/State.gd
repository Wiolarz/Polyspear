extends Node

class_name State

enum TAG \
{
	IDLE,
	ATTACK,
	DEFEND,
}

@export var tags : Array[TAG] = []

@export var StartingState : bool = false



func _ready():
	if not StartingState:
		set_process(false)



