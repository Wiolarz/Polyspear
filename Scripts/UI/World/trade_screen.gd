extends Control

@onready var first_army_panel : VBoxContainer = $HBoxContainer/FirstArmyPanel
@onready var second_army_panel : VBoxContainer = $HBoxContainer/SecondArmyPanel


var first_army : Army
var second_army : Army


func _ready():
	first_army_panel.unit_was_selected.connect(attempt_a_unit_transfer)
	second_army_panel.unit_was_selected.connect(attempt_a_unit_transfer)



func start_trade(first_army_ : Army, second_army_ : Army) -> void:
	show()
	first_army = first_army_
	second_army = second_army_
	first_army_panel.load_army(first_army)
	second_army_panel.load_army(second_army)




func attempt_a_unit_transfer():
	## one of the armies is full, and they swap units
	if first_army_panel.selected_unit_pointer and second_army_panel.selected_unit_pointer:
		succesful_transfer()
		return

	# attempt to move unit from first army to the second:
	if first_army_panel.selected_unit_pointer and second_army.units_data.size() != second_army.hero.max_army_size:
		succesful_transfer()
		return

	# attempt to move unit from second army to the first:
	if second_army_panel.selected_unit_pointer and first_army.units_data.size() != first_army.hero.max_army_size:
		succesful_transfer()
		return







func succesful_transfer():
	var unit : DataUnit
	if first_army_panel.selected_unit_pointer:
		unit = first_army_panel.selected_unit_pointer
		first_army.units_data.erase(unit)
		second_army.units_data.append(unit)

	if second_army_panel.selected_unit_pointer:
		unit = second_army_panel.selected_unit_pointer
		second_army.units_data.erase(unit)
		first_army.units_data.append(unit)

	first_army_panel.transfered_unit()
	second_army_panel.transfered_unit()





## after trade UI was hidden, it can be re-opened through "show" button
func _show_trade() -> void:
	$HBoxContainer.show()
	$HideButton.text = "Hide Trade"


func hide_trade() -> void:
	$HBoxContainer.hide()
	$HideButton.text = "Show Trade"


func end_trade() -> void:
	hide()




func _on_hide_button_pressed():
	if $HBoxContainer.visible:
		hide_trade()
	else:
		_show_trade()
		

func _on_close_button_pressed():
	end_trade()
