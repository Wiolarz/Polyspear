extends LevelUpScreen


# override
func _setup() -> void:
	tier_panels_container = get_node("TierPanels")


func load_selected_hero_level_up_screen(hero : Hero) -> void:
	selected_hero = hero
	chosen_abilities = [[], [], []]
	chosen_talents = [-1, -1, -1]
	for tier_panel in tier_panels_container.get_children():
		tier_panel.set_hero(selected_hero, true)
	$HeroLevelValue.text = "Hero Level: " + str(selected_hero.level)


func _on_button_confirm_pressed():
	apply_talents_and_abilities()
	WM.world_ui.try_to_close_context_menu()
