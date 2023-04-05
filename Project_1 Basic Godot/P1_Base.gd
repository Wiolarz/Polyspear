extends Node

"""
Example project showcasing general gaming related code
Which aims to explain general programming in godot
"""



func _ready():  # Runs at the start of the game
	print("Start Project 1")
	gameplay_1()




func gameplay_1():
	var hp = 10
	print(hp)
	hp -= 1
	print(hp)




func gameplay_2():
	var enemy_hp = 10
	print(enemy_hp)
	
	var attack_speed = 3
	var attack_damage = 2
	
	enemy_hp -= (attack_damage * attack_speed)
	
	print(enemy_hp)

'''
zrob cos w stylu fale przeciwnikow
'''


func gameplay_3():
	# Shitty armor system
	var enemy_hp = 20
	var enemy_armor = 3
	print(enemy_hp)
	
	var attack_speed = 4
	var attack_damage = 6
	
	for attack in range(attack_speed):
		enemy_hp -= attack_damage - enemy_armor
		#enemy_hp -= clamp((attack_damage - enemy_armor), 0, enemy_hp)
	
		print(enemy_hp)

func gameplay_4():
	# Slightly better armor system
	var enemy_hp = 20
	var enemy_armor = 3  # 0.3 --> 70% dmg dealt
	print(enemy_hp)
	
	var attack_speed = 4
	var attack_damage = 6
	
	for attack in range(attack_speed):
		enemy_hp -= attack_damage * (1 - (enemy_armor / 10))
	
		print(enemy_hp)


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
	
	
