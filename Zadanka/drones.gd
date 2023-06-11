extends Node


func _ready():
	
	var i = 0
	while i < 10:
		i += 1
		var dron1 = 1
		var dron2 = 2
		var dron3 = 3
		
		var hp = 0
		var player_power = 0
		# cycle 1
		print("Giant nuclear beast - extreme challenge")
		var challenge = 4
		var player_input = randi_range(1, 3)
		
		if player_input == 1:
			if dron1 > 0:
				player_power = dron1
				dron1 = 0
			elif dron2 > 0:
				player_power = dron2
				dron2 = 0
			else:
				player_power = dron3
				dron3 = 0
		elif player_input == 2:
			if dron2 > 0:
				player_power = dron2
				dron2 = 0
			elif dron1 > 0:
				player_power = dron1
				dron1 = 0
			else:
				player_power = dron3
				dron3 = 0
		else:
			if dron3 > 0:
				player_power = dron3
				dron3 = 0
			elif dron2 > 0:
				player_power = dron2
				dron2 = 0
			else:
				player_power = dron1
				dron1 = 0
		

		if challenge >= player_power:
			hp -= 1
		
		print("A couple of mutants with guns running around - medium challenge")
		challenge = 2
		player_input = randi_range(1, 3)
		
		if player_input == 1:
			if dron1 > 0:
				player_power = dron1
				dron1 = 0
			elif dron2 > 0:
				player_power = dron2
				dron2 = 0
			else:
				player_power = dron3
				dron3 = 0
		elif player_input == 2:
			if dron2 > 0:
				player_power = dron2
				dron2 = 0
			elif dron1 > 0:
				player_power = dron1
				dron1 = 0
			else:
				player_power = dron3
				dron3 = 0
		else:
			if dron3 > 0:
				player_power = dron3
				dron3 = 0
			elif dron2 > 0:
				player_power = dron2
				dron2 = 0
			else:
				player_power = dron1
				dron1 = 0
		

		if challenge >= player_power:
			hp -= 1
		
		print("Few wolves running around - weak challenge")
		challenge = 1
		player_input = randi_range(1, 3)
		
		if player_input == 1:
			if dron1 > 0:
				player_power = dron1
				dron1 = 0
			elif dron2 > 0:
				player_power = dron2
				dron2 = 0
			else:
				player_power = dron3
				dron3 = 0
		elif player_input == 2:
			if dron2 > 0:
				player_power = dron2
				dron2 = 0
			elif dron1 > 0:
				player_power = dron1
				dron1 = 0
			else:
				player_power = dron3
				dron3 = 0
		else:
			if dron3 > 0:
				player_power = dron3
				dron3 = 0
			elif dron2 > 0:
				player_power = dron2
				dron2 = 0
			else:
				player_power = dron1
				dron1 = 0
		

		if challenge >= player_power:
			hp -= 1
		
		
		print("Final score: ", hp)
	
