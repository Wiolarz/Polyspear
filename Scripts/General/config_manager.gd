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


func _physics_process(_delta):
	if Input.is_action_just_pressed("KEY_BOT_SPEED_SLOW"):
		animation_speed = AnimationSpeed.NORMAL
		bot_speed = BotSpeed.FREEZE
	elif Input.is_action_just_pressed("KEY_BOT_SPEED_MEDIUM"):
		animation_speed = AnimationSpeed.NORMAL
		bot_speed = BotSpeed.NORMAL
	elif Input.is_action_just_pressed("KEY_BOT_SPEED_FAST"):
		animation_speed = AnimationSpeed.INSTANT
		bot_speed = BotSpeed.FAST
