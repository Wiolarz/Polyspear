extends Place
class_name Deposit

var accumulated_goods : Goods = Goods.new()

func interact(army : ArmyOnWorldMap):
	collect(army.controller)

func collect(player : Player):
	player.goods.add(accumulated_goods)
	accumulated_goods.clear()