extends Control

@onready var first_army_panel : VBoxContainer = $HBoxContainer/FirstTradeArmyPanel
@onready var second_army_panel : VBoxContainer = $HBoxContainer/SecondTradeArmyPanel

## Selected hero from World Manager
var first_army : Army
## Could be a second hero or a city garrison
var second_army : Army


func _ready():
	first_army_panel.unit_was_selected.connect(_attempt_a_unit_transfer)
	first_army_panel.army_swap.connect(_army_swap)
	second_army_panel.unit_was_selected.connect(_attempt_a_unit_transfer)
	second_army_panel.army_swap.connect(_army_swap)



func start_trade(first_army_ : Army, second_army_ : Army) -> void:
	show()
	first_army = first_army_
	second_army = second_army_
	first_army_panel.load_army(first_army)
	second_army_panel.load_army(second_army)





func _attempt_a_unit_transfer() -> void:
	## one of the armies is full, and they swap units
	if first_army_panel.selected_unit_pointer and second_army_panel.selected_unit_pointer:
		_succesful_transfer()
		return

	# attempt to move unit from first army to the second:
	if first_army_panel.selected_unit_pointer and second_army.units_data.size() <= second_army.max_army_size:
		_succesful_transfer()
		return

	# attempt to move unit from second army to the first:
	if second_army_panel.selected_unit_pointer and first_army.units_data.size() != first_army.max_army_size:
		_succesful_transfer()
		return


func _succesful_transfer() -> void:
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


func _army_swap() -> void:
	print("army swap")
	if first_army.hero.movement_points > 0:
		## You can always move into a city
		if not second_army.hero or second_army.hero.movement_points > 0:
			WS.swap_armies(first_army, second_army)
			if not second_army.hero:
				first_army.hero.is_in_city = true
				if second_army.units_data.size() > 0:
					first_army.units_data.append_array(second_army.units_data)
					second_army.units_data = []
					WM.world_ui.refresh_army_panel()
				end_trade()


func end_trade() -> void:
	WM.world_ui.close_context_menu()


func _on_close_button_pressed():
	end_trade()
