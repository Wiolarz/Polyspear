extends LevelUpScreen

var selected_hero : Hero

# override
func _setup() -> void:
	tier_panels_container = get_node("TierPanels")


func load_selected_hero_level_up_screen(hero : Hero) -> void:
	selected_hero = hero  # not duplicated - confirm button will edit the slot data_hero
	for tier_panel in tier_panels_container.get_children():
		tier_panel.set_hero(selected_hero)
	$HeroLevelValue.text = "Hero Level: " + str(selected_hero.level)


# override
func apply_talents_and_abilities() -> void:
	for tier in range(3):
		var talent_idx = chosen_talents[tier]
		if talent_idx > 0:
			var new_talent : HeroPassive = CFG.talents[tier][talent_idx - 1]
			if new_talent not in selected_hero.passive_effects:
				selected_hero.passive_effects.append(new_talent)

		for ability_idx : int in chosen_abilities[tier]:
			var new_ability : HeroPassive = CFG.abilities[tier][ability_idx - 1]
			if new_ability not in selected_hero.passive_effects:
				selected_hero.passive_effects.append(new_ability)


func _on_button_confirm_pressed():
	apply_talents_and_abilities()
	#if WM.world_game_is_active():
	WM.world_ui.try_to_close_context_menu()
