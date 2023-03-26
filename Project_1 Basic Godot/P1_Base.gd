extends Node

func _ready():
	print("Start Project 1")


func _input(event):
	pass
	#if event.is_action_pressed("KEY_1"):
	#		print("1")

func _process(delta):
	# Input.is_action_pressed
	var input_value = 0
	if Input.is_action_just_released("KEY_1"):
		print("1")
		input_value = 1
	elif Input.is_action_just_released("KEY_2"):
		print("2")
		input_value = 2
	elif Input.is_action_just_released("KEY_3"):
		print("3")
		input_value = 3
	'if Input.is_action_just_released("KEY_2"):
		print("2")'
	
	if input_value > 1:
		print("Jak najbardziej! Jeszcze JAK!")
	
	
