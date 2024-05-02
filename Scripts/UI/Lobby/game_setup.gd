class_name GameSetup
extends Control

# VERY IMPORTANT TODO:
# move all modifications of IM.game_setup_info to some controller -- it
# should not be modified directly by GUI

@export var client_side : bool

@onready var button_battle = \
	$MarginContainer/VBoxContainer/ModeChoice/ButtonBattle
@onready var button_full_scenario = \
	$MarginContainer/VBoxContainer/ModeChoice/ButtonFullScenario
@onready var container : Control = \
	$MarginContainer/VBoxContainer/SetupContainer


@onready var multi_world_setup = load("res://Scenes/UI/Lobby/WorldSetup.tscn")
@onready var multi_battle_setup = load("res://Scenes/UI/Lobby/BattleSetup.tscn")


var current_player_to_set : String = "" # if empty we select for us


func clear_container():
	for child in container.get_children():
		container.remove_child(child)


func select_full_scenario():
	_select_setup_page(multi_world_setup)


func select_battle():
	_select_setup_page(multi_battle_setup)


func _select_setup_page(page):
	clear_container()
	var setup = page.instantiate()
	container.add_child(setup)
	setup.game_setup = self
	if client_side:
		setup.make_client_side()
	setup.refresh()


func refresh_after_conenction_change():
	# this refresh is to change our username when we start or stop server ;)
	if container.get_child_count() == 1:
		var setup = container.get_child(0)
		if setup is MultiBattleSetup or setup is WorldSetup:
			setup.refresh()


func force_full_rebuild():
	if container.get_child_count() == 1:
		var setup = container.get_child(0)
		if setup is MultiBattleSetup or setup is WorldSetup:
			setup.rebuild()
			setup.refresh()



func try_to_take_slot(index : int) -> bool:
	var slots = IM.game_setup_info.slots
	if index < 0 or index > slots.size():
		return false
	if NET.client:
		NET.client.queue_take_slot(index)
		return false # we will change this after server responds
	slots[index].occupier = current_player_to_set
	if NET.server:
		NET.server.broadcast_full_game_setup(IM.game_setup_info)
	return true


func try_to_leave_slot(index : int) -> bool:
	var slots = IM.game_setup_info.slots
	if index < 0 or index > slots.size():
		return false
	if slots[index].occupier != current_player_to_set:
		return false
	if NET.client:
		NET.client.queue_leave_slot(index)
		return false # we will change this after server responds
	slots[index].occupier = 0 # set basic computer here
	if NET.server:
		NET.server.broadcast_full_game_setup(IM.game_setup_info)
	return true

# TODO move to input manager or somewhere
func try_to_cycle_color_slot(index : int, backwards : bool) -> bool:
	var slots = IM.game_setup_info.slots
	if index < 0 or index > slots.size():
		return false
	if NET.client:
		NET.client.queue_cycle_color(index, backwards)
		return false # we will change this after server responds
	var new_color_index = slots[index].color
	var diff : int = 1 if not backwards else -1
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
	if NET.server:
		NET.server.broadcast_full_game_setup(IM.game_setup_info)
	return true


func try_to_cycle_faction_slot(index : int, backwards : bool) -> bool:
	var slots = IM.game_setup_info.slots
	if index < 0 or index > slots.size():
		return false
	var diff : int = 1 if not backwards else -1
	if NET.client:
		NET.client.queue_cycle_faction(index, backwards)
		return false # we will change this after server responds
	var faction_index = CFG.FACTIONS_LIST.find(slots[index].faction)
	var new_faction_index = \
		(faction_index + diff) % CFG.FACTIONS_LIST.size()
	slots[index].faction = CFG.FACTIONS_LIST[new_faction_index]
	print("faction: ",index," --> ",slots[index].faction.get_network_id())
	if NET.server:
		NET.server.broadcast_full_game_setup(IM.game_setup_info)
	return true


func try_to_set_world_map_name(map_name : String) -> bool:
	# drut
	IM.game_setup_info.world_map = load("%s/%s" % [ CFG.WORLD_MAPS_PATH, map_name ])
	if NET.server:
		NET.server.broadcast_full_game_setup(IM.game_setup_info)
	# TODO here load this map and adjust slot number
	return true


func _on_button_full_scenario_toggled(toggled_on : bool):
	if toggled_on:
		select_full_scenario()


func _on_button_battle_toggled(toggled_on : bool):
	if toggled_on:
		select_battle()


func _ready():
	IM.game_setup_info_changed.connect(refresh_after_conenction_change)
	button_battle.button_pressed = true
	button_battle.button_group = button_full_scenario.button_group


func _on_button_confirm_pressed():
	container.get_child(0).start_game() # mały drucik
