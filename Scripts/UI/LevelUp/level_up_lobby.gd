extends LevelUpScreen


var selected_hero : DataHero
@onready var hero_level_value : OptionButton = $VBox/HeroLevelValue

func _setup() -> void:
	hero_level_value.set_item_text(0, "1")  # mockup cleanup
	tier_panels_container = get_node("VBox/TierPanels")


func load_lobby_level_up_screen(data_hero : DataHero) -> void:
	selected_hero = data_hero  # not duplicated - confirm button will edit the slot data_hero
	for tier_panel in tier_panels_container.get_children():
		tier_panel.set_hero_level(data_hero.starting_level)
	hero_level_value.selected = data_hero.starting_level - 1
	hero_level_value.text = "Hero Level: " + str(hero_level_value.selected + 1)


# override
func apply_talents_and_abilities() -> void:
	selected_hero.starting_passives = []
	for tier in range(3):
		var talent_idx = chosen_talents[tier]
		if talent_idx > 0:
			var new_talent : HeroPassive = CFG.talents[tier][talent_idx - 1]
			if new_talent not in selected_hero.starting_passives:
				selected_hero.starting_passives.append(new_talent)

		for ability_idx : int in chosen_abilities[tier]:
			var new_ability : HeroPassive = CFG.abilities[tier][ability_idx - 1]
			if new_ability not in selected_hero.starting_passives:
				selected_hero.starting_passives.append(new_ability)


func _on_hero_level_value_item_selected(_index : int):
	var hero_level : int = hero_level_value.selected + 1
	hero_level_value.text = "Hero Level: " + str(hero_level)
	for tier_panel : PanelContainer in tier_panels_container.get_children():
		tier_panel.set_hero_level(hero_level)
	selected_hero.starting_level = hero_level
