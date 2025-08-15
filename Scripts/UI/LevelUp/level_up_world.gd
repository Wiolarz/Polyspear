extends LevelUpScreen


# override
func _get_tier_panel_children() -> Array[Node]:
	return get_node("TierPanels").get_children()


func load_selected_hero_level_up_screen(hero : Hero) -> void:
	selected_hero = hero
	chosen_abilities = [[], [], []]
	chosen_talents = [-1, -1, -1]
	for tier_panel in tier_panels:
		tier_panel.set_hero(selected_hero, true)
	$HeroLevelValue.text = "Hero Level: " + str(selected_hero.level)


func _on_button_confirm_pressed():
	apply_talents_and_abilities()
	WM.world_ui.try_to_close_context_menu()
