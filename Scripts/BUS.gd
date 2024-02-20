extends Node

var Attacker_wins = 0
var Defender_wins = 0


enum bot_speed_values
{# time in frames to make a move (60 = 1 sec, 30 = 0.5 sec)
	FREEZE = 0,
	NORMAL = 30,
	FAST = 1,
}
var BotSpeed : bot_speed_values = bot_speed_values.NORMAL


enum animation_speed_values
{
	NORMAL = 30,
	INSTANT = 666,
}
var animation_speed : animation_speed_values = animation_speed_values.NORMAL 



signal collect_save_data(save: Save)
signal load_game(save: Save)


#var player_reference : CharacterBody2D
