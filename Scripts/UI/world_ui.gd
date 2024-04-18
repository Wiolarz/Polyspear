class_name WorldUI
extends CanvasLayer

@onready var good_label : Label = $HBoxContainer/GoodsLabel

func _on_menu_pressed():
	IM.show_in_game_menu()


func _on_switch_camera_pressed():
	assert(false, "not implemented")


func show_trade_ui(city : City, hero : ArmyOnWorldMap):
	_refresh_units_to_buy(city, hero)
	_refresh_army_display(hero)
	$CityUi.show()


func _refresh_units_to_buy(city : City, hero : ArmyOnWorldMap):
	var units = city.get_units_to_buy()
	var buy_children = $CityUi/HBoxContainer/Buy.get_children()
	for i in range(buy_children.size()-1):
		var b = buy_children[i+1] as Button
		b.text = "-empty-"
		for s in b.get_signal_connection_list("pressed"):
			b.disconnect("pressed", s.callable)
		if i < units.size():
			b.text = units[i].unit_name
			
			b.pressed.connect(_buy_unit.bind(units[i], hero))


func _refresh_army_display(hero : ArmyOnWorldMap):
	var army_children = $CityUi/HBoxContainer/Army.get_children()
	for i in range(army_children.size()-1):
		var b = army_children[i+1] as Button
		b.text = "-empty-"
		if i < hero.army_data.units_data.size():
			b.text = hero.army_data.units_data[i].unit_name


func _buy_unit(unit : DataUnit, hero : ArmyOnWorldMap):
	print("buy", unit.unit_name)
	
	if hero.army_data.units_data.size() >= \
		$CityUi/HBoxContainer/Army.get_child_count() - 1 :
			print("army size limit")
			return

	hero.army_data.units_data.append(unit)
	_refresh_army_display(hero)
	

func _on_city_ui_close_requested():
	$CityUi.hide()


func _on_end_turn_pressed():
	WM.next_player_turn()
	

func _process(_delta):

	good_label.text = "%d 🪓| %d ⛏️| %d 💎" % WM.current_player.goods.to_array()
