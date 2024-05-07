class_name CityUi
extends Control

var viewed_city : City
var visiting_hero : ArmyForm

@onready var hero_recruit = $HeroRecruitment
@onready var unit_recruit = $RecruitUnits
@onready var buildings = $Buildings


func show_trade_ui(city : City, hero : ArmyForm):
	viewed_city = city
	visiting_hero = hero
	_refresh_all()


func _refresh_all():
	_refresh_heroes_to_buy()
	_refresh_units_to_buy()
	_refresh_army_display()
	_refresh_buildings_display()


func _refresh_heroes_to_buy():
	var heroes = viewed_city.get_heroes_to_buy()
	var buy_hero_children = $HeroRecruitment.get_children()
	for i in range(buy_hero_children.size()):
		var hero_panel = buy_hero_children[i]
		var button = hero_panel.get_node("BuyHeroButton")
		button.text = "Buy hero\n" + str(heroes[i].cost)
		button.disabled = W_GRID.get_army(viewed_city.coord) != null or \
			not viewed_city.controller.has_enough(heroes[i].cost)
		for s in button.pressed.get_connections():
			button.pressed.disconnect(s["callable"])
		button.pressed.connect(_on_buy_hero_button_pressed.bind(i))
		hero_panel.get_node("HeroImage").texture = \
			load(heroes[i].data_unit.texture_path)


func _refresh_units_to_buy():
	var units = viewed_city.get_units_to_buy()
	var buy_children = $RecruitUnits/UnitsToBuy.get_children()
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
	var army_children : Array = $RecruitUnits/VisitingHeroArmy.get_children()
	for i in range(army_children.size()-1):
		var b = army_children[i+1] as Button
		b.text = "-empty-"
		b.disabled = not visiting_hero
		if visiting_hero and i < visiting_hero.entity.units_data.size():
			b.text = visiting_hero.entity.units_data[i].unit_name


func _buy_unit(unit):
	print("trying to buy ", unit.unit_name)

	if visiting_hero.entity.units_data.size() >= \
			$RecruitUnits/VisitingHeroArmy.get_child_count() - 1 :
		print("army size limit")
		return

	if not visiting_hero.controller.purchase(unit.cost):
		print("not enough cash, needed ",unit.cost)
		return

	visiting_hero.entity.units_data.append(unit)
	_refresh_all()


func _on_buy_hero_button_pressed(hero_index : int):
	print("trying to buy a hero ")

	var hero : DataHero = viewed_city.controller.faction.heroes[hero_index]

	if not viewed_city.controller.purchase(hero.cost):
		print("not enough cash, needed ", hero.cost)
		return

	WM.recruit_hero(viewed_city.controller, hero, viewed_city.coord)
	_refresh_all()


func _refresh_buildings_display():
	var buildings_data = viewed_city.controller.faction.buildings
	for i in range(buildings_data.size()):
		var building_data = buildings_data[i]
		var b_button = buildings.get_child(i+1) as Button
		if not b_button:
			continue
		var description = str(building_data.cost)
		if viewed_city.has_build(building_data):
			description = "✔"
		b_button.text = "%s\n%s" % [building_data.name, description]
		b_button.disabled = not viewed_city.can_build(building_data)
		for s in b_button.pressed.get_connections():
			b_button.pressed.disconnect(s["callable"])
		b_button.pressed.connect(func build():
			viewed_city.build(building_data)
			_refresh_all()
		)


func _on_show_recruit_heroes_ui_pressed():
	unit_recruit.hide()
	buildings.hide()
	hero_recruit.visible = not hero_recruit.visible


func _on_show_recruit_units_ui_pressed():
	hero_recruit.hide()
	buildings.hide()
	unit_recruit.visible = not unit_recruit.visible


func _on_show_build_ui_pressed():
	hero_recruit.hide()
	unit_recruit.hide()
	buildings.visible = not buildings.visible
