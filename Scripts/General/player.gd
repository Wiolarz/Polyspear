class_name Player
extends Node

var player_name : String = ""

var bot_engine : AIInterface

var faction : DataFaction

var goods : Goods = Goods.new()

var capital_city : City:
	get:
		if cities.size() == 0:
			return null
		return cities[0]
	set(_wrong_value):
		assert(false, "attempt to modify read only value of player capital_city")

var cities : Array[City]

var hero_armies : Array[ArmyForm] = []

var dead_heroes: Array[Hero] = []

func _init():
	name = "Player"


func use_bot(bot_enabled : bool):
	if bot_enabled == (bot_engine != null):
		return
	if not bot_enabled:

		bot_engine.queue_free()
		bot_engine = null
	else:
		bot_engine = ExampleBot.new(self)
		add_child(bot_engine)


## let player know its his turn,
## in case play is AI, call his decision maker
func your_turn():
	print("your move " + player_name)

	if bot_engine != null and not NET.client: # AI is simulated on server only
		bot_engine.play_move()


func set_capital(capital : City):
	capital.controller = self
	cities.append(capital)


## Checks if player has enough goods for purchase
func has_enough(cost : Goods) -> bool:
	return goods.has_enough(cost)


## If there are sufficient goods returns true + goods are subtracted
func purchase(cost : Goods) -> bool:
	if goods.has_enough(cost):
		goods.subtract(cost)
		return true
	print("not enough money")
	return false


func hero_recruited(hero : ArmyForm):
	hero_armies.append(hero)


func hero_died(hero : Hero):
	var i = 0
	while i < hero_armies.size():
		if hero_armies[i].entity.hero == hero:
			hero_armies.remove_at(i)
		else:
			i += 1

	dead_heroes.append(hero)


func has_hero(data_hero: DataHero):
	for ha in hero_armies:
		if ha.entity.hero.template == data_hero:
			return true
	return false


func has_dead_hero(data_hero: DataHero):
	for dh in dead_heroes:
		if dh.template == data_hero:
			return true
	return false


func get_hero_cost(data_hero: DataHero):
	if has_dead_hero(data_hero):
		return data_hero.revive_cost
	return data_hero.cost
