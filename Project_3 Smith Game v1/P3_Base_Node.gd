extends Node

"""
Game about managing your knight equipment

knight has statistics that increase over time. He brings you stuff with which you can create EQ

Statistics requirements for items works drain attributes pool example:
Knight with 5 STR can wear sword 4 STR and Armor 1 STR
if he had chosen a sword with 3 STR he could additionally take a 1 STR shield

"""


func _ready():
	print("Start Project 3")





var game_state = "main"

var resources = {
	"stone": 0,
	"wood": 0,
	"bronze": 0,
	"iron": 0,
	"silver": 0,
	"gold": 0,
	"platinum": 0,
}



func generate_item_list():
	var item_names = ["stone_sword", "wood_sword", "bronze_sword", 
	"iron_sword", "silver_sword", "gold_sword"]

	var item_list = []
	for name in item_names:
		item_list.append(Item.new(name))
	return item_list


class Item:
	
	var item_stats = {
	"stone_sword": {"atk": 1},
	"wood_sword": {"atk": 1},
	"bronze_sword": {"atk": 1},
	"iron_sword": {"atk": 1},
	"silver_sword": {"atk": 1},
	"gold_sword": {"atk": 1},
		
	}
	var item_cost = {
	"stone_sword": {"stone": 1},
	"wood_sword": {"wood": 1},
	"bronze_sword": {"bronze": 1},
	"iron_sword": {"iron": 1},
	"silver_sword": {"silver": 1},
	"gold_sword": {"gold": 1},
		
	}
	func _init(name):
		self.cost = item_cost[name]
		self.stats = item_stats[name]



class Knight:
	func _init():
		pass
	




func gameplay_state_controller(input):
	var output_text = str(input)
	pass



func _process(delta):

	var input_value = 0
	if Input.is_action_just_released("KEY_1"):
		input_value = 1
	elif Input.is_action_just_released("KEY_2"):
		input_value = 2
	elif Input.is_action_just_released("KEY_3"):
		input_value = 3
	
	if input_value != 0:
		gameplay_state_controller(input_value)
	
