class_name CityUi
extends Control

var viewed_city : City
var visiting_hero : ArmyForm

func show_trade_ui(city : City, hero : ArmyForm):
	viewed_city = city
	visiting_hero = hero
	_refresh_heroes_to_buy()
	_refresh_units_to_buy()
	_refresh_army_display()


func _refresh_heroes_to_buy():
	var heroes = viewed_city.controller.faction.heroes
	$HeroRecruitment/RecruitHeroLayout/HeroImage.texture = \
			load(heroes[0].data_unit.texture_path)
	var button = $HeroRecruitment/RecruitHeroLayout/BuyHeroButton
	button.text = "Buy hero\n" + str(heroes[0].cost)
	button.disabled = W_GRID.get_army(viewed_city.coord) != null or \
		not viewed_city.controller.has_enough(heroes[0].cost)


func _refresh_units_to_buy():
	var units = viewed_city.get_units_to_buy()
	var buy_children = $RecruitUnitsUI.get_children()
	for i in range(buy_children.size()-1):
		var b = buy_children[i+1] as Button
		b.text = "-empty-"
		for s in b.get_signal_connection_list("pressed"):
			b.disconnect("pressed", s.callable)
		if i < units.size():
			var unit = units[i]
			b.text = unit.cost.to_string_short("-") + " -> "+ unit.unit_name
			b.pressed.connect(_buy_unit.bind(unit))
			b.disabled = not visiting_hero


func _refresh_army_display():
	#TODO CLEAN
	var army_children : Array = $Army.get_children()
	for i in range(army_children.size()-1):
		var b = army_children[i+1] as Button
		b.text = "-empty-"
		b.disabled = not visiting_hero
		if visiting_hero and i < visiting_hero.entity.units_data.size():
			b.text = visiting_hero.entity.units_data[i].unit_name


func _buy_unit(unit):
	print("trying to buy ", unit.unit_name)

	if visiting_hero.entity.units_data.size() >= \
			$Army.get_child_count() - 1 :
		print("army size limit")
		return

	if not visiting_hero.controller.purchase(unit.cost):
		print("not enough cash, needed ",unit.cost)
		return

	visiting_hero.entity.units_data.append(unit)
	_refresh_army_display()

func _on_buy_hero_button_pressed():
	print("trying to buy a hero ")

	var hero : DataHero = viewed_city.controller.faction.heroes[0]

	if not viewed_city.controller.purchase(hero.cost):
		print("not enough cash, needed ", hero.cost)
		return

	WM.recruit_hero(viewed_city.controller, hero, viewed_city.coord)

	_refresh_heroes_to_buy()
