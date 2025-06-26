# TierPanel
extends PanelContainer


signal talent_chosen(tier_idx : int, button_idx : int)

signal ability_chosen(tier_idx : int, button_idx : int, diselect : bool)



var setup_ui : BattleSetup = null

var tier : int


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


func ability_pressed(pressed_button_idx : int):
	print("ability " + str(pressed_button_idx))

	if not ability_buttons[pressed_button_idx].button_pressed:  # Deselects
		ability_chosen.emit(tier, pressed_button_idx, false)
		for ability_button in ability_buttons:
			ability_button.disabled = false
		return

	ability_chosen.emit(tier, pressed_button_idx, true)


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

