# TierPanel
extends PanelContainer


signal talent_chosen(tier_idx : int, button_idx : int)

signal ability_chosen(tier_idx : int, button_idx : int, diselect : bool)


var tier : int
var hero_level : int


@onready var tier_name = $MainContainer/TierLabel

@onready var talent_buttons : Array[Button] = [
	$MainContainer/TierUpgrades/PowerPassiveButton,
	$MainContainer/TierUpgrades/TacticPassiveButton,
	$MainContainer/TierUpgrades/MagicPassiveButton
]
@onready var ability_buttons : Array[Button] = [
	$MainContainer/TierSkills/PowerSkillButton,
	$MainContainer/TierSkills/TacticSkillButton,
	$MainContainer/TierSkills/MagicSkillButton,
]

# STUB
func init_tier_panel(tier_ : int, _race : DataRace) -> void:
	tier_name.text = "TIER - " + str(tier_ + 1)
	tier = tier_
	var button_idx : int = -1
	for ability_button in ability_buttons:
		button_idx += 1
		var lambda = func on_click():
			ability_pressed(button_idx)
		ability_button.pressed.connect(lambda)

	button_idx = -1
	for talent_button in talent_buttons:
		button_idx += 1
		var lambda = func on_click():
			talent_pressed(button_idx)
		talent_button.pressed.connect(lambda)


func set_hero_level(hero_level_ : int) -> void:
	hero_level = hero_level_
	var number_of_avalaible_abilities : int = (hero_level + 1) - ((tier * 2) - 1)

	var can_choose_talent : bool = true
	if tier == 1 and hero_level == 1:
		can_choose_talent = false
	elif (hero_level - ((tier * 2) - 1)) < 0:  # 3 or 5
		can_choose_talent = false

	if not can_choose_talent:
		disable_talents()
	else:
		for talent_button in talent_buttons:   # enable buttons
			talent_button.disabled = false

	if number_of_avalaible_abilities == 1:
		disable_abilities(true)
	elif number_of_avalaible_abilities < 1:
		disable_abilities(false)
	else:
		for ability_button in ability_buttons:  # enable buttons
			ability_button.disabled = false



func disable_talents() -> void:
	talent_chosen.emit(tier, 0)  # deselects
	for talent_button in talent_buttons:
		talent_button.button_pressed = false
		talent_button.disabled = true


func disable_abilities(only_one : bool = false) -> void:
	if not only_one: # disable all abilities
		for button_idx in range(3):
			if ability_buttons[button_idx].button_pressed:
				ability_buttons[button_idx].button_pressed = false
				ability_pressed(button_idx) # Deselects

		for ability_button in ability_buttons:
			ability_button.disabled = true
		return

	# disable only_one ability
	var one_is_chosen : bool = false
	for button_idx in range(3):
		if ability_buttons[button_idx].button_pressed and not one_is_chosen:
			one_is_chosen = true
			continue
		elif ability_buttons[button_idx].button_pressed:
			ability_buttons[button_idx].button_pressed = false
			ability_pressed(button_idx) # Deselects

	for ability_button in ability_buttons:
		if not ability_button.pressed:
			ability_button.disabled = true


func ability_pressed(pressed_button_idx : int):
	print("ability " + str(pressed_button_idx))

	if not ability_buttons[pressed_button_idx].button_pressed:  # Deselects
		ability_chosen.emit(tier, pressed_button_idx, false)
		for ability_button in ability_buttons:
			ability_button.disabled = false
		return

	ability_chosen.emit(tier, pressed_button_idx, true)

	var number_of_avalaible_abilities : int = (hero_level + 1) - ((tier * 2) - 1)
	assert(number_of_avalaible_abilities > 0, "ability button was not properly disabled")

	if number_of_avalaible_abilities == 1:  ## Hero can have only one Ability
		var button_idx = -1
		for ability_button in ability_buttons:
			button_idx += 1
			if pressed_button_idx != button_idx:
				assert(not ability_button.button_pressed)
				ability_button.disabled = true
		return

	## Hero can have two Abilities
	var buttons_indexes : Array[int] = [0, 1, 2]
	for button_idx in range(3):
		if ability_buttons[button_idx].button_pressed:
			buttons_indexes.erase(button_idx)

	if buttons_indexes.size() == 2:
		return

	if buttons_indexes.size() == 1:  # Two buttons are pressed -> disable 3rd one
		ability_buttons[buttons_indexes[0]].disabled = true


func talent_pressed(pressed_button_idx : int):
	print("talent " + str(pressed_button_idx))
	if talent_buttons[pressed_button_idx].pressed:
		talent_chosen.emit(tier, pressed_button_idx)
	else:
		talent_chosen.emit(tier, 0)  # resets the state
		return

	var button_idx = -1
	for talent_button in talent_buttons:
		button_idx += 1
		if pressed_button_idx != button_idx:
			talent_button.button_pressed = false

