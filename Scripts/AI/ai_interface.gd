class_name AIInterface extends Node


var me : Player


func _init(controlled_player : Player):
	me = controlled_player


func play_move(_battle_state : BattleGridState):
	print("ERROR", me, " AI interface has not been implemented")
