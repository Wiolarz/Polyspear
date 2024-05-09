extends Node

signal player_death


# loading player, and enemy characters objects
# TODO research if ONREADY here is neccesary
var player_charater_scene = load("res://Scenes/player_character.tscn")
var guard_charater_scene = load("res://Scenes/guard_character.tscn")


var player_deaths = 2

var current_location = "test"



func _ready() -> void:
	print("Start of the Krong 10")
	city_creation()



func city_creation():
	"""
	Create a basic city and starting player character
	"""
	var city = []
	var number_of_locations = 3
	for i in range(number_of_locations):
		city.append([])

	var player = generate_player()

	print(player.get_node("EQ_System").levels)
	#add_child(player_character)
	city[0].append(player)

	var guard_character = guard_charater_scene.instantiate()
	#add_child(guard_character)

	#var city = get_children()
	for i in range(number_of_locations - 1):
		city[i + 1].append(guard_character.duplicate())

	print(city)
#	print(player)
	#print(city[0].get_node("Health_System").light_points)
#	for i in range(10):
#		var random_target = randi_range(0, city.size() - 1)
#		city[random_target].get_node("Health_System").light_damage(1)
#		removing_dead(city)
#		print(city)

	var random_target = 0
	city[0][random_target].get_node("Health_System").light_damage(10)
	removing_dead(city)
	player.die()
	print(player.get_node("EQ_System").levels)
	print(city[0][random_target].get_node("EQ_System").levels)
	print(city)


func generate_player():
	var node = player_charater_scene.instantiate()
	add_child(node)
	var random_rewards = ["food", "iron", "gold"]
	for i in range(player_deaths):
		var reward = random_rewards.pick_random()
		node.get_node("EQ_System").level_up(reward)
	return node



func removing_dead(city):
	"""
	Health check of all the characters inside the city
	"""
	for location in city:
		var to_be_killed = []
		for i in range(location.size()):
			var obj = location[i]
			if obj.get_node("Health_System").is_dead():
				if obj is player_character:
					emit_signal("player_death")  # testing if neccesary
					player_deaths += 1
					city[0].append(generate_player())

				to_be_killed.append(i)

		var modifier = 0
		for value in to_be_killed:
			location.remove_at(value - modifier)
			modifier += 1

