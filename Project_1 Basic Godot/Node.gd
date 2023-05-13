extends Node

var rng = RandomNumberGenerator.new()

signal chosen(num)

var ranger = {
	"class": "ranger",
	"hp": 10,
	"base_atk": 2,
	"dice": [6, 4]
}

var tank = {
	"class": "tank",
	"hp": 20,
	"base_atk": 4,
	"dice": [2, 3]
}

var tp = [ranger.duplicate(true), tank.duplicate(true)]
var tb = [ranger.duplicate(true), ranger.duplicate(true)]


func _ready():
	var tura = 0
	while (true):
		tura += 1
		print("tura ", tura)
		var bot_choice = rng.randi_range(0,len(tb)-1)
		var player_choice = yield(self, "chosen") -1
		if player_choice >= len(tp):
			continue
		var tp_atk = 0
		var p_character = tp[player_choice]
		for dice in p_character.dice:
			tp_atk += p_character.base_atk + rng.randi_range(1,dice)
		var tb_atk = 0
		var b_character = tb[bot_choice]
		for dice in b_character.dice:
			tb_atk += b_character.base_atk + rng.randi_range(1,dice)
		b_character.hp -= tp_atk
		p_character.hp -= tb_atk
		print("twój ", p_character.class, " atakuje ", b_character.class, " za ", tp_atk, ", wrogowi zostaje ", b_character.hp, "hp")
		print(b_character.class, " atakuje twojego ", p_character.class, " za ", tb_atk, ", twojemu bohaterowi zostaje ", p_character.hp, "hp")
		var temp = range(len(tp))
		temp.invert()
		for i in temp:
			if tp[i].hp <= 0:
				print("twój ", tp[i].class, " umarł, rip")
				tp.remove(i)
		temp = range(len(tb))
		temp.invert()
		for i in temp:
			print(tb[i])
			if tb[i].hp <= 0:
				print("wrogi ", tb[i].class, " umarł")
				tb.remove(i)
		if len(tb) <= 0 and len(tp) <= 0:
			print("brawo oboje się powybijaliście")
		elif len(tp) <= 0:
			print("przegrałeś")
		elif len(tb) <= 0:
			print("wygrałeś")
		else:
			continue
		get_tree().quit()

func _input(event):
	if event.is_action_pressed("choose_1"):
		emit_signal("chosen", 1)
	elif event.is_action_pressed("choose_2"):
		emit_signal("chosen", 2)


