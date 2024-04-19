extends Place
class_name Deposit

var accumulated_goods : Goods
var per_turn : Goods

func _init(start : Goods, gain_per_turn : Goods):
	accumulated_goods = start.duplicate()
	per_turn = gain_per_turn.duplicate()

func interact(army : ArmyOnWorldMap):
	collect(army.controller)

func on_end_of_turn():
	accumulated_goods.add(per_turn)

func get_map_description() -> String:
	var result = "|"
	if accumulated_goods.wood > 0:
		result += "%d 🪓|" % accumulated_goods.wood
	if accumulated_goods.iron > 0:
		result += "%d ⛏️|" % accumulated_goods.iron
	if accumulated_goods.ruby > 0:
		result += "%d 💎|" % accumulated_goods.ruby
	if result == "|":
		result = "Nothing"
	return result

func collect(player : Player):
	player.goods.add(accumulated_goods)
	accumulated_goods.clear()
