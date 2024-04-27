class_name MultiBattleSetup
extends Control

var game_setup : MultiGameSetup

var player_slot_panels = []

@onready var player_list = \
	$Slots/ColorRect/PlayerList

@onready var maps_list : OptionButton = \
	$MapSelect/ColorRect/MapList


func _ready():
	rebuild()
	fill_maps_list()


func start_game():
	var map_name = maps_list.get_item_text(maps_list.selected)
	var map_data = load(CFG.BATTLE_MAPS_PATH + "/" + map_name)
	var players : Array[Player] = []
	var armies : Array[Army] = []

	for playerIdx in range(2):
		var player = create_player(playerIdx)
		players.append(player)
		armies.append(create_army(playerIdx, player))
	IM.players = players

	UI.go_to_main_menu()
	BM.start_battle(armies, map_data)

func is_ai(playerIdx : int) -> bool:
	return player_slot_panels[playerIdx].is_bot()

func create_player(playerIdx : int) -> Player:
	if playerIdx == 0:
		var elf = Player.new();
		elf.faction = CFG.FACTION_ELVES
		elf.player_name = "elf"
		elf.use_bot(is_ai(playerIdx))
		elf.goods = CFG.get_start_goods()
		return elf

	var orc = Player.new()
	orc.faction = CFG.FACTION_ORCS
	orc.player_name = "orc"
	orc.use_bot(is_ai(playerIdx))
	orc.goods = CFG.get_start_goods()
	return orc

func create_army(_playerIdx:int, player:Player) -> Army:
	var army = Army.new()
	army.controller = player
	army.units_data.append(load("res://Resources/Battle/Units/Elves/elf1.tres"))
	return army


func refresh():
	for index in range(player_slot_panels.size()):
		refresh_slot(index)


func refresh_slot(index : int):
	if not index in range(player_slot_panels.size()):
		return
	var ui_slot : BattlePlayerSlotPanel = player_slot_panels[index]
	var logic_slot : GameSetupInfo.Slot = \
		IM.game_setup_info.slots[index] if index in \
				range(IM.game_setup_info.slots.size()) \
			else null
	var color : Color = CFG.DEFAULT_TEAM_COLOR
	var username : String = ""
	var faction : DataFaction = null
	var take_leave_button_state : BattlePlayerSlotPanel.TakeLeaveButtonState =\
		BattlePlayerSlotPanel.TakeLeaveButtonState.GHOST
	if logic_slot:
		if logic_slot.occupier is String:
			if logic_slot.occupier == "":
				username = IM.get_current_name()
				take_leave_button_state = \
					BattlePlayerSlotPanel.TakeLeaveButtonState.TAKEN_BY_YOU
			else:
				username = logic_slot.occupier
				take_leave_button_state = \
					BattlePlayerSlotPanel.TakeLeaveButtonState.TAKEN_BY_OTHER
		else:
			username = "Computer\nlevel %d" % logic_slot.occupier
			take_leave_button_state = \
				BattlePlayerSlotPanel.TakeLeaveButtonState.FREE
		faction = logic_slot.faction
		color = CFG.get_team_color_at(logic_slot.color)
	ui_slot.set_visible_color(color)
	ui_slot.set_visible_name(username)
	ui_slot.set_visible_take_leave_button_state(take_leave_button_state)
	ui_slot.setup_ui = self


func slot_to_index(slot) -> int:
	return player_slot_panels.find(slot)


func try_to_take_slot(slot) -> bool: # true means something changed
	if not game_setup:
		return false
	var index : int = slot_to_index(slot)
	var changed = game_setup.try_to_take_slot(index)
	if changed:
		refresh_slot(index)
	return changed


func try_to_leave_slot(slot) -> bool:
	if not game_setup:
		return false
	var index : int = slot_to_index(slot)
	var changed = game_setup.try_to_leave_slot(index)
	if changed:
		refresh_slot(index)
	return changed


func cycle_color_slot(slot : BattlePlayerSlotPanel, backwards : bool) -> bool:
	if not game_setup:
		return false
	var index : int = slot_to_index(slot)
	var changed = game_setup.try_to_cycle_color_slot(index, backwards)
	if changed:
		refresh_slot(index)
	return changed


func cycle_faction_slot(slot : BattlePlayerSlotPanel, backwards : bool) -> bool:
	if not game_setup:
		return false
	var index : int = slot_to_index(slot)
	var changed = game_setup.try_to_cycle_faction_slot(index, backwards)
	if changed:
		refresh_slot(index)
	return changed


func rebuild():
	player_slot_panels = []
	for slot in player_list.get_children():
		player_slot_panels.append(slot)
	# don't want to refresh here -- we want to be able to build this widget
	# without real data


func fill_maps_list():
	var maps = IM.get_battle_maps_list()
	for map_name in maps:
		maps_list.add_item(map_name)
