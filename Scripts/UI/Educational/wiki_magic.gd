extends Panel

@onready var button_columns : Array[VBoxContainer] = [ \
	$Margin/VBoxContainer/HBoxContainer/Scroll/VBox/HBoxContainer/Column1,
	$Margin/VBoxContainer/HBoxContainer/Scroll/VBox/HBoxContainer/Column2,
	$Margin/VBoxContainer/HBoxContainer/Scroll/VBox/HBoxContainer/Column3]


@onready var spell_information_title = $Margin/VBoxContainer/HBoxContainer/SpellInformationContainer/VBox/SpellName
@onready var spell_information_description = $Margin/VBoxContainer/HBoxContainer/SpellInformationContainer/VBox/RichTextLabel
@onready var spell_information_icon = $Margin/VBoxContainer/HBoxContainer/SpellInformationContainer/VBox/TextureRect


func _ready():
	generate_battle_spell_buttons()


func load_spell(battle_spell : BattleSpell) -> void:
	spell_information_title.text = battle_spell.name
	spell_information_icon.texture = load(battle_spell.icon_path)

	var text_description = ""
	match battle_spell.name:
		"Blood Ritual":
			text_description += "Chosen enemy unit will die after it becomes the last unit left alive on the enemy side \n\n" + \
			"Spell cannot be casted if enemy has less than 3 units left."

		"Fireball":
			text_description += "Chosen tile explodes killing every nearby unit in range of 1 tile\n\n" +\
			"Currently enemy unit are killed first, but soon it will be reversed."
		"Martyr":
			text_description += "Chosen a friendly unit -> it along with casters are now connected through martyr bond.\n\n" +\
			"If one were to die, the other one dies instead and the first one is teleport to the sacrificed unit spot"
		"Teleport":
			text_description += "Choose a tile in front of the caster, caster is teleported there activating his attacks"
		"Vengeance":
			text_description += "Choose an ally unit -> For the next 6 turns \n" +\
			"if an enemy unit during their turn were to make a move, leading to this units death, it will die too\n\n" +\
			"But if it were to be the last unit killed, spell won't take effect as the battle will be over."
		"Wind Dash":
			text_description += "Choose a tile directly in front of the caster ->\n" +\
			 "Caster traverses 3 tiles forward attacking before getting hit by enemy spears.\n\n" +\
			"If unit along casters path were to survive his attacks. (ex. because it had a shield)\n" +\
			"Caster will be squashed"


	spell_information_description.text = text_description


func generate_battle_spell_buttons() -> void:
	# clean mockup ui
	for column in button_columns:
		for mock_button in column.get_children():
			mock_button.queue_free()

	var path = CFG.SPELLS_PATH
	var dir = DirAccess.open(path)
	var spell_idx : int = -1
	for battle_spell_file_path in dir.get_files():
		spell_idx += 1

		var battle_spell : BattleSpell = load(path + battle_spell_file_path)
		if spell_idx == 0:
			load_spell(battle_spell)

		var button : WikiSpellButton = load("res://Scenes/UI/Wiki/wiki_spell_button.tscn").instantiate()
		button_columns[spell_idx % button_columns.size()].add_child(button)
		button.load_spell(battle_spell)

		button.selected.connect(load_spell)
