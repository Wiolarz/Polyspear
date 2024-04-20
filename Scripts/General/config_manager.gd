# Singleton - CFG
extends Node

enum BotSpeed
{# delay between AI moves in frames (60 = 1 sec, 30 = 0.5 sec)
	FREEZE = 0,
	NORMAL = 30,
	FAST = 1,
}
var bot_speed : BotSpeed = BotSpeed.NORMAL


enum AnimationSpeed
{
	NORMAL = 30,
	INSTANT = 666,
}
var animation_speed : AnimationSpeed = AnimationSpeed.NORMAL
