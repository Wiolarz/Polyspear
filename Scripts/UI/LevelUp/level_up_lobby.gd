extends LevelUpScreen


var selected_hero : Hero
@onready var hero_level_value : OptionButton = $VBox/HeroLevelValue

func _setup() -> void:
	hero_level_value.set_item_text(0, "1")  # mockup cleanup
	tier_panels_container = get_node("VBox/TierPanels")


func load_lobby_level_up_screen(hero : Hero) -> void:
	selected_hero = hero  # not duplicated - confirm button will edit the slot data_hero
	for tier_panel in tier_panels_container.get_children():
		tier_panel.set_hero(hero)
	hero_level_value.selected = hero.level - 1
	hero_level_value.text = "Hero Level: " + str(hero_level_value.selected + 1)


# override
func apply_talents_and_abilities() -> void:
	selected_hero.passive_effects = []
	for tier in range(3):
		var talent_idx = chosen_talents[tier]
		if talent_idx >= 0:
			var new_talent : HeroPassive = CFG.talents[tier][talent_idx]
			if new_talent not in selected_hero.passive_effects:
				selected_hero.passive_effects.append(new_talent)

		for ability_idx : int in chosen_abilities[tier]:
			var new_ability : HeroPassive = CFG.abilities[tier][ability_idx]
			if new_ability not in selected_hero.passive_effects:
				selected_hero.passive_effects.append(new_ability)


func _on_hero_level_value_item_selected(_index : int):
	var hero_level : int = hero_level_value.selected + 1
	hero_level_value.text = "Hero Level: " + str(hero_level)
	selected_hero.level = hero_level
	for tier_panel : PanelContainer in tier_panels_container.get_children():
		tier_panel.set_hero(selected_hero)
