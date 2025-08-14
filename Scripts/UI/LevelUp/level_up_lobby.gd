extends LevelUpScreen


@onready var hero_level_value : OptionButton = $VBox/HeroLevelValue


func _setup() -> void:
	hero_level_value.set_item_text(0, "1")  # mockup cleanup
	tier_panels_container = get_node("VBox/TierPanels")


func load_lobby_level_up_screen(hero : Hero) -> void:
	selected_hero = hero
	chosen_abilities = [[], [], []]
	chosen_talents = [-1, -1, -1]
	for tier_panel in tier_panels_container.get_children():
		tier_panel.set_hero(hero, false)
	hero_level_value.selected = hero.level - 1
	hero_level_value.text = "Hero Level: " + str(hero.level)


func _on_hero_level_value_item_selected(_index : int):
	var hero_level : int = hero_level_value.selected + 1
	hero_level_value.text = "Hero Level: " + str(hero_level)
	selected_hero.level = hero_level
	for tier_panel : PanelContainer in tier_panels_container.get_children():
		tier_panel.set_hero(selected_hero)
