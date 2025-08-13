class_name LevelUpScreen
extends Control


@onready var children = get_children()  # scene is static

var tier_panels_container : VBoxContainer


## Each number represents choice from subsequent tier [br]
##  0 - No Talent taken [br]
## 1-3 Might, Tactic, Magic
var chosen_talents : Array[int] = [0, 0, 0]

## 3 sub arrays Each coresponds each tier [br]
## Tier can have at most two numbers [br]
## If number appears this ability has been chosen [br]
## 1-3 Might, Tactic, Magic
var chosen_abilities : Array = [[], [], []]

## Currently there is no difference between level up for various races so level up screen can be generated once
func _ready() -> void:
	_setup()
	var tier_idx = -1
	for tier_panel in tier_panels_container.get_children():
		tier_idx += 1
		tier_panel.init_tier_panel(tier_idx, null)
		tier_panel.talent_chosen.connect(_selected_talent)
		tier_panel.ability_chosen.connect(_selected_ability)
		tier_panel.set_hero_level(1)


# to be overriden
func _setup() -> void:
	pass


# to be overriden
func apply_talents_and_abilities() -> void:
	pass


func _selected_talent(tier : int, button_idx : int) -> void:
	#print(tier, button_idx)
	chosen_talents[tier] = button_idx


func _selected_ability(tier : int, button_idx : int, selected : bool) -> void:
	#print(tier, button_idx)
	if selected:
		chosen_abilities[tier].append(button_idx)
		assert(chosen_abilities[tier].size() <= 2)
	else:
		chosen_abilities[tier].erase(button_idx)
