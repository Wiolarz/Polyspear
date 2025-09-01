extends Panel

@onready var race_selection_buttons_column : VBoxContainer = $Margin/VBoxContainer/HBoxContainer/VBoxRaceSelection


@onready var race_information_title = $Margin/VBoxContainer/HBoxContainer/RaceInformationContainer/VBox/RaceName
@onready var race_information_description = $Margin/VBoxContainer/HBoxContainer/RaceInformationContainer/VBox/RichTextLabel
@onready var race_information_icon = $Margin/VBoxContainer/HBoxContainer/RaceInformationContainer/VBox/TextureRect


@onready var race_heroes_list_container : HBoxContainer = \
$Margin/VBoxContainer/HBoxContainer/RaceInformationContainer/VBox/HBoxHeroes

@onready var race_units_list_container : HBoxContainer = \
$Margin/VBoxContainer/HBoxContainer/RaceInformationContainer/VBox/HBoxUnits




@onready var race_button_template : Resource = load("res://Scenes/UI/Wiki/WorldWiki/WikiRaceButton.tscn")
@onready var unit_button_template : Resource = load("res://Scenes/UI/Wiki/BattleWiki/WikiUnitButton.tscn")



func _ready():
	generate_race_buttons()


func load_race(race : DataRace) -> void:
	race_information_title.text = race.race_name.capitalize()
	race_information_icon.texture = load(race.units_data[0].texture_path) # TODO add icons to each race

	race_information_description.text = race.description


	# clean previous display
	for button in race_heroes_list_container.get_children():
		button.queue_free()
	for button in race_units_list_container.get_children():
		button.queue_free()

	for hero in race.heroes:
		var button : WikiUnitButton = unit_button_template.instantiate()
		race_heroes_list_container.add_child(button)
		button.load_unit(hero.data_unit)
	for unit in race.units_data:
		var button : WikiUnitButton = unit_button_template.instantiate()
		race_units_list_container.add_child(button)
		button.load_unit(unit)




func generate_race_buttons() -> void:
	# clean mockup ui
	for mock_button in race_selection_buttons_column.get_children():
		mock_button.queue_free()

	var race_idx = -1
	for race_data in CFG.RACES_LIST:
		race_idx += 1

		if race_idx == 0:  # load first race automatically
			load_race(race_data)

		var button : WikiRaceButton = race_button_template.instantiate()
		race_selection_buttons_column.add_child(button)
		button.load_race(race_data)

		button.selected.connect(load_race)
