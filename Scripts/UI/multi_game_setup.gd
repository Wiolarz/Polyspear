class_name MultiGameSetup
extends Control

# VERY IMPORTANT TODO:
# move all modifications of IM.game_setup_info to some controller -- it
# should not be modified directly by GUI

@onready var button_battle = \
	$MarginContainer/VBoxContainer/ModeChoice/ButtonBattle
@onready var button_full_scenario = \
	$MarginContainer/VBoxContainer/ModeChoice/ButtonFullScenario
@onready var container : Control = \
	$MarginContainer/VBoxContainer/SetupContainer


const multi_scenario_setup = preload("res://Scenes/UI/MultiScenarioSetup.tscn")
const multi_battle_setup = preload("res://Scenes/UI/MultiBattleSetup.tscn")


var current_player_to_set : String = "" # if empty we select for us


func clear_container():
	for child in container.get_children():
		container.remove_child(child)


func select_full_scenario():
	_select_setup_page(multi_scenario_setup)


func select_battle():
	_select_setup_page(multi_battle_setup)


func _select_setup_page(page):
	clear_container()
	var setup = page.instantiate()
	container.add_child(setup)
	setup.game_setup = self
	setup.refresh()


func refresh_after_conenction_change():
	# this refresh is to change our username when we start or stop server ;)
	if container.get_child_count() == 1:
		var battle_setup = container.get_child(0)
		if battle_setup is MultiBattleSetup:
			battle_setup.refresh()


func try_to_take_slot(index : int) -> bool:
	var slots = IM.game_setup_info.slots
	if index < 0 or index > slots.size():
		return false
	# if we are a client:
		# send request to take this slot
		# return false # we will change this after server responds
	slots[index].occupier = current_player_to_set
	# if we are server:
		# broadcasst this change to everyone (probably the result of it, not
		# only the fact)
	return true


func try_to_leave_slot(index : int) -> bool:
	var slots = IM.game_setup_info.slots
	if index < 0 or index > slots.size():
		return false
	if slots[index].occupier != current_player_to_set:
		return false
	# if we are a client:
		# send request to leave this slot
		# return false # we will change this after server responds
	slots[index].occupier = 0 # set basic computer here
	# if we are a server:
		# broadcasst this change to everyone (probably the result of it, not
		# only the fact)
	return true

# TODO move to input manager or somewhere
func try_to_cycle_color_slot(index : int, backwards : bool) -> bool:
	var slots = IM.game_setup_info.slots
	if index < 0 or index > slots.size():
		return false
	var diff : int = 1 if not backwards else -1
	# if we are a client:
		# send request cycle color of this slot
		# return false # we will change this after server responds
	var new_color_index = slots[index].color
	while true:
		new_color_index = (new_color_index + diff) % CFG.TEAM_COLORS.size()
		if new_color_index == slots[index].color: # all colors are taken
			return false
		var is_color_unique = func() -> bool:
			for slot in slots:
				if slot.color == new_color_index:
					return false
			return true
		if is_color_unique.call():
			slots[index].color = new_color_index
			break
	# if we are a server:
		# broadcasst this change to everyone (probably the result of it, not
		# only the fact)
	return true


func try_to_cycle_faction_slot(index : int, backwards : bool) -> bool:
	var slots = IM.game_setup_info.slots
	if index < 0 or index > slots.size():
		return false
	var diff : int = 1 if not backwards else -1
	# if we are a client:
		# send request cycle faction of this slot
		# return false # we will change this after server responds
	var faction_index = IM.WIP_factions.find(slots[index].faction)
	var new_faction_index = \
		(faction_index + diff) % IM.WIP_factions.size()
	slots[index].faction = IM.WIP_factions[new_faction_index]
	# if we are a server:
		# broadcasst this change to everyone (probably the result of it, not
		# only the fact)
	return true


func _on_button_full_scenario_toggled(toggled_on : bool):
	if toggled_on:
		select_full_scenario()


func _on_button_battle_toggled(toggled_on : bool):
	if toggled_on:
		select_battle()


func _enter_tree():
	# need to do it here, not in _ready because _on_button_battle_toggled gets
	# called before it
	IM.set_default_game_setup_info()



func _ready():
	button_battle.button_pressed = true
	button_battle.button_group = button_full_scenario.button_group


func get_player_settings() -> Array[PlayerSetting]:
	var elf = PlayerSetting.new();
	elf.faction = CFG.FACTION_ELVES
	elf.player_name = "asd"
	elf.player_type =  E.player_type.HUMAN
	elf.goods = Goods.new(0,0,0)

	var orc = PlayerSetting.new()
	orc.faction = CFG.FACTION_ORCS
	orc.player_name = "asd"
	orc.player_type =  E.player_type.HUMAN
	orc.goods = Goods.new(0,0,0)

	return [ elf, orc ]

func _on_button_confirm_pressed():
	UI.go_to_main_menu()
	IM.start_game("small6x6.tres", get_player_settings())
