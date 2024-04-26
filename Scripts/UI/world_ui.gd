class_name WorldUI
extends CanvasLayer

var city_on_ui : City

@onready var good_label : Label = $HBoxContainer/GoodsLabel


func _process(_delta):
	good_label.text = WM.current_player.goods.to_string()

func refresh_player_buttons():
	var player_buttons = $Players.get_children()
	for i in range(player_buttons.size() - 1):
		var selected = WM.players[i] == WM.current_player
		var button = player_buttons[i+1] as Button
		button.text = WM.players[i].player_name
		button.modulate = Color.RED if selected else Color.WHITE

func show_trade_ui(city : City, hero : ArmyForm):
	city_on_ui = city
	_refresh_heroes_to_buy(city)
	_refresh_units_to_buy(city, hero)
	_refresh_army_display(hero)
	$CityUi.show()


func close_city_ui() -> void:
	city_on_ui = null
	$CityUi.hide()


func _on_menu_pressed():
	IM.show_in_game_menu()


func _on_switch_camera_pressed():
	print("not implemented")


func _refresh_heroes_to_buy(city : City):
	var heroes = city.controller.faction.heroes
	$CityUi/HBoxContainer/VBoxContainer/HeroImage.texture = \
			load(heroes[0].data_unit.texture_path)
	var button = $CityUi/HBoxContainer/VBoxContainer/BuyHeroButton
	button.text = "Buy hero\n"+str(heroes[0].cost)
	button.disabled = W_GRID.get_army(city.coord) != null or \
		not city.controller.has_enough(heroes[0].cost)


func _refresh_units_to_buy(city : City, hero : ArmyForm):
	var units = city.get_units_to_buy()
	var buy_children = $CityUi/HBoxContainer/Buy.get_children()
	for i in range(buy_children.size()-1):
		var b = buy_children[i+1] as Button
		b.text = "-empty-"
		for s in b.get_signal_connection_list("pressed"):
			b.disconnect("pressed", s.callable)
		if i < units.size():
			var unit = units[i]
			b.text = unit.cost.to_string_short("-") + " -> "+ unit.unit_name
			b.pressed.connect(_buy_unit.bind(unit, hero))
			b.disabled = not hero


func _refresh_army_display(hero : ArmyForm):
	var army_children = $CityUi/HBoxContainer/Army.get_children()
	for i in range(army_children.size()-1):
		var b = army_children[i+1] as Button
		b.text = "-empty-"
		b.disabled = not hero
		if hero and i < hero.entity.units_data.size():
			b.text = hero.entity.units_data[i].unit_name
			# print(i, b.text )


func _buy_unit(unit : DataUnit, hero_army : ArmyForm):
	print("trying to buy ", unit.unit_name)

	if hero_army.entity.units_data.size() >= \
			$CityUi/HBoxContainer/Army.get_child_count() - 1 :
		print("army size limit")
		return

	if !hero_army.controller.purchase(unit.cost):
		print("not enough cash, needed ",unit.cost)
		return

	hero_army.entity.units_data.append(unit)
	_refresh_army_display(hero_army)


func _on_city_ui_close_requested():
	close_city_ui()

func _on_end_turn_pressed():
	WM.next_player_turn()
	refresh_player_buttons()

func _on_buy_hero_button_pressed():
	print("trying to buy a hero ")

	var hero = city_on_ui.controller.faction.heroes[0]

	if !city_on_ui.controller.purchase(hero.cost):
		print("not enough cash, needed ", hero.cost)
		return

	WM.recruit_hero(city_on_ui.controller, hero, city_on_ui.coord)

	_refresh_heroes_to_buy(city_on_ui)
