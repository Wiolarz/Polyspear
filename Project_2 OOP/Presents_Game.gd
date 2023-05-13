extends Object

"""
Game about buying presents for your kid

Version 1:
you have certain income, some of that income is used to purchase your kids some presents.

Every money not spent, is saved up.

Later in the game more expensive presents are unlocked but the income doesn’t increase that strongly
increasing the need for saving up.

"""


class_name Presents_Game


func __init__():
	pass


var game_state = "main"

var pay = 10
var money = 10

static func start():
	print("Start Presents_Game")

var kindergarden_things_to_buy = {
	"candy": 1,
	"teddy bear": 3,
	"lego duplo": 5,
	"electric car": 9,
}

var primaryschool_things_to_buy = {
	"toy cars": 3,
	"lego set": 5,
	"board game": 8,
	"gaming console": 11,
}

var middleschool_things_to_buy = {
	"toy cars": 3,
	"lego set": 5,
	"board game": 8,
	"computer": 11,
}

var highschool_things_to_buy = {
	"books": 2,
	"lego set": 5,
	"money": 10,
	"computer": 13,
}

var age = 0
var age_groups = [kindergarden_things_to_buy, primaryschool_things_to_buy,
middleschool_things_to_buy, highschool_things_to_buy]


func gameplay_state_controller(input):
	if input == 0:
		print(age_groups[0])
		print("Your funds: ", money)
		return
	if len(age_groups) == age:
		return
	
	
	money - age_groups[age][input]
	print(age_groups[age][input], money)
	age += 1
	if len(age_groups) == age:
		return
	print(age_groups[age])


func _process(delta):

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
	elif Input.is_action_just_released("KEY_4"):
		print("4")
		input_value = 4
	
	if input_value != 0:
		gameplay_state_controller(input_value)
	
