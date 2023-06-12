extends Node
# TODO research if ONREADY here is neccesary
var player_charater_scene = load("res://Kings_Hunt/player_character.tscn")  
var guard_charater_scene = load("res://Kings_Hunt/guard_character.tscn") 

func _ready() -> void:
	print("Start of the Krong 9")
	test()


"""
max_hand_size = 3
[1, 2, 3, 4]

[1, 2]  [3, 4]

[1] [2, 3, 4] []
[] [2, 3, 4] [1]


up, down, wait, search
1, 2, 3, 4, [0]



"""



func test():
	""" try to create fresh player character and enemy character
	deal damage ot one of them randomly and then if someone dies 
	a new character is spawned
	"""
	var city = []
#	var number_of_locations = 3
#	for i in range(number_of_locations):
#		city.append([])
	
	var player_character = player_charater_scene.instantiate()
	
	#add_child(player_character)
	city.append(player_character)
	
	
	var guard_character = guard_charater_scene.instantiate()
	#add_child(guard_character)
	
	#var city = get_children()
	for i in range(4):
		city.append(guard_character)  # .duplicate()
	
	print(city)
#	print(player_character)
	#print(city[0].get_node("Health_System").light_points)
#	for i in range(10):
#		var random_target = randi_range(0, city.size() - 1)
#		city[random_target].get_node("Health_System").light_damage(1)
#		removing_dead(city)
#		print(city)

	var random_target = 2
	city[random_target].get_node("Health_System").light_damage(10)
	removing_dead(city)
	#removing_dead(city)
	#removing_dead(city)
	print(city)


func removing_dead(location):
	"""
	It's a placeholder function for testing character damage
	"""
	var to_be_killed = []
	for i in range(location.size()):
		var obj = location[i]
		print(obj.get_node("Health_System").heavy_points)
		if obj.get_node("Health_System").is_dead():
			if obj is player_character:
				pass # TODO send signal that a new character has to be made
			#print("dead")
			to_be_killed.append(i)
	var modifier = 0
	for value in to_be_killed:
		location.remove_at(value - modifier)
		modifier += 1
			
