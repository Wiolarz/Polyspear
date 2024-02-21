extends Node

class_name Card_System

@export var controller : Controller_System  # 

var full_deck = [12, 5, 8, 12, 5, 8, 2, 4, 6]
var current_deck = []
var used_cards = []
var hand = []
var draw_power = 1
var max_hand_size = 3

var fatigue_status = 0

func sleep():
	current_deck = full_deck
	current_deck.shuffle()
	fatigue_status = 0

func fatigue(): 
	# TODO check if this could be made into lambda expresion within draw
	fatigue_status += 1
	current_deck = used_cards
	current_deck.shuffle()

func draw(number=1):
	
	while number > 0 and hand.size() < max_hand_size:
		number -= 1
		if current_deck.size() == 0:
			fatigue()
		hand.append(current_deck[0])
		current_deck.pop_at(0)
			

func use_card(hand_pos=0):
	var card = hand[hand_pos]
	hand.remove_at(hand_pos)
	used_cards.append(card)
	return card - fatigue_status

