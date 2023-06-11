extends Node
# export node arrays are bugged in godot 4.0
@export var attack_button1 : Button  
@export var attack_button2 : Button
@export var attack_button3 : Button
@onready var attack_buttons = [attack_button1, attack_button2, attack_button3]

# normally you would want to use:
#@export var attack_button : Array[Button] = [null, null, null]


func new_question():
	"""
	reset previous choice
	highlight possible choices based on circumstances
	
	"""
	pass


	
func _physics_process(delta):
	"""
	
	"""
	var current_choice = null
	var possible_action_inputs = \
	{"KEY_Q": "hide", "KEY_W": "run_up", "KEY_E": "run_down"}
	var possible_card_inputs = \
	{"KEY_1": 0, "KEY_2": 1, "KEY_3": 2, "KEY_4": 3,}
		
	# input
	for key in possible_action_inputs.keys():
		if Input.is_action_just_pressed(key):
			current_choice = possible_action_inputs[key]
	for key in possible_card_inputs.keys():
		if Input.is_action_just_pressed(key):
			current_choice = possible_card_inputs[key]

	
		
		if current_choice == "run":
			level += 1
			location = generate_room()
		elif next_attack != null:  # Fight
			var combat_power = 0
			var combat_choice = ["combat_1", "combat_2", "combat_3"]
			if current_choice in combat_choice:
				combat_choice = combat_choice.find(current_choice)
				if player.cooldowns[combat_choice] == 0:
					player.cooldowns[combat_choice] = player.cooldown_reset
					combat_power = player.attacks[combat_choice]
			if combat_power < next_attack:
				player.hp -= 1
				if player.hp == 0:
					output.text = "game over"
					return
		else:  # mine
			for i in range(player.mine_power):
				
				var choice = location.keys()
				if choice.size() == 0:
					break
				choice.shuffle()
				choice = choice[0]
				player.award_resource(choice)
				location[choice] -= 1
				if location[choice] == 0:
					location.erase(choice)
			
		
		# reset turn
		current_choice = "mine"
		for i in range(player.cooldowns.size()):
			if player.cooldowns[i] > 0:
				player.cooldowns[i] -= 1
		time = 0
		generate_attack()
		state_print()
		# new info
	
		
		


func _on_button_1_pressed() -> void:
	current_choice = "mine"


func _on_button_2_pressed() -> void:
	current_choice = "run"


func _on_button_3_pressed() -> void:
	current_choice = "combat_1"


func _on_button_4_pressed() -> void:
	current_choice = "combat_2"


func _on_button_5_pressed() -> void:
	current_choice = "combat_3"

	

	

