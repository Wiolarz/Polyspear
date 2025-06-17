extends CanvasLayer


@onready var hide_button : Button = $ButtonHide

@onready var children = get_children()  # scene is static

@onready var tier_panels : VBoxContainer = $TierPanels


var hidden : bool = true

var selected_hero : Hero


## Currently there is no difference between level up for various races so level up screen can be generated once
func _ready():

	var tier_idx = 0
	for tier_panel in tier_panels.get_children():
		tier_idx += 1
		tier_panel.init_tier_panel(tier_idx, null)


func load_level_up_screen(data_hero : DataHero) -> void:
	$HeroLevelValue.set_item_text(0, "1")
	$HeroLevelValue.selected = data_hero.starting_level - 1
	$HeroLevelValue.text = "Hero Level: " + str($HeroLevelValue.selected + 1)


func _on_hero_level_value_item_selected(index : int):
	$HeroLevelValue.text = "Hero Level: " + str($HeroLevelValue.selected + 1)



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
	hidden = true
	hide()
