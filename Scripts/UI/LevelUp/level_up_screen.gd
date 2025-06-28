extends CanvasLayer


@onready var hide_button : Button = $ButtonHide

@onready var children = get_children()  # scene is static

@onready var tier_panels : VBoxContainer = $TierPanels


var hidden : bool = true

var selected_hero : DataHero

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
func _ready():
	var tier_idx = -1
	for tier_panel in tier_panels.get_children():
		tier_idx += 1
		tier_panel.init_tier_panel(tier_idx, null)
		tier_panel.talent_chosen.connect(_selected_talent)
		tier_panel.ability_chosen.connect(_selected_ability)
		tier_panel.set_hero_level(1)


func load_level_up_screen(data_hero : DataHero) -> void:
	selected_hero = data_hero  # not duplicated - confirm button will edit the slot data_hero
	$HeroLevelValue.set_item_text(0, "1")
	$HeroLevelValue.selected = data_hero.starting_level - 1
	$HeroLevelValue.text = "Hero Level: " + str($HeroLevelValue.selected + 1)


func _on_hero_level_value_item_selected(_index : int):
	var hero_level : int = $HeroLevelValue.selected + 1
	$HeroLevelValue.text = "Hero Level: " + str(hero_level)
	for tier_panel : PanelContainer in tier_panels.get_children():
		tier_panel.set_hero_level(hero_level)


func apply_talents_and_abilities() -> void:
	for tier in range(3):
		var talent_idx = chosen_talents[tier]
		if talent_idx > 0:
			var new_talent : HeroPassive = CFG.talents[tier][talent_idx - 1]
			if new_talent not in selected_hero.starting_passives:
				selected_hero.starting_passives.append(new_talent)

		for ability_idx : int in chosen_abilities[tier]:
			var ability : HeroPassive = CFG.abilities[tier][ability_idx - 1]
			if ability not in selected_hero.starting_passives:
				selected_hero.starting_passives.append(ability)


func _selected_talent(tier : int, button_idx : int) -> void:
	print(tier, button_idx)
	chosen_talents[tier] = button_idx


func _selected_ability(tier : int, button_idx : int, selected : bool) -> void:
	print(tier, button_idx)
	if selected:
		chosen_abilities[tier].append(button_idx)
		assert(chosen_abilities[tier].size() <= 2)
	else:
		chosen_abilities[tier].erase(button_idx)


func _on_button_hide_pressed():
	if hidden:
		for child in children:
			child.show()
		hidden = false
		return
	hidden = true
	for child in children:
		child.hide()

	hide_button.show()


func _on_button_confirm_pressed():
	apply_talents_and_abilities()
	hidden = true
	hide()
