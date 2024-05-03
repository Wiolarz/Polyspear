class_name BattleSetup
extends Control

var game_setup : GameSetup

var player_slot_panels = []

var client_side_map_label : Label

@onready var player_list = \
	$Slots/ColorRect/PlayerList

@onready var maps_list : OptionButton = \
	$MapSelect/ColorRect/MapList

@onready var presets_list : OptionButton = \
	$PresetSelect/ColorRect/PresetList

func _ready():
	rebuild()
	fill_maps_list()
	fill_presets_list()


func make_client_side():
	$MapSelect/Label.text = "Selected map"
	$MapSelect/ColorRect.remove_child(maps_list)
	maps_list.queue_free()
	maps_list = null
	client_side_map_label = Label.new()
	client_side_map_label.text = "some map"
	$MapSelect/ColorRect.add_child(client_side_map_label)
	remove_child($PresetSelect)


func refresh():
	for index in range(player_slot_panels.size()):
		refresh_slot(index)

	if client_side_map_label:
		var map_name = DataBattleMap.get_network_id(IM.game_setup_info.battle_map)
		client_side_map_label.text = map_name


func refresh_slot(index : int):
	if index < 0 or index >= player_slot_panels.size():
		push_error("no ui slot to refresh on index ", index)
		return

	var ui_slot : BattlePlayerSlotPanel = player_slot_panels[index]
	var logic_slot : GameSetupInfo.Slot = \
		IM.game_setup_info.slots[index] if IM.game_setup_info.has_slot(index) \
			else null
	var color : Color = CFG.DEFAULT_TEAM_COLOR
	var username : String = ""
	var faction : DataFaction = null
	var take_leave_button_state : BattlePlayerSlotPanel.TakeLeaveButtonState =\
		BattlePlayerSlotPanel.TakeLeaveButtonState.GHOST
	if logic_slot:
		if logic_slot.occupier is String:
			ui_slot.button_ai.text = "HUMAN"
			if logic_slot.occupier == "":
				username = NET.get_current_login()
				take_leave_button_state = \
					BattlePlayerSlotPanel.TakeLeaveButtonState.TAKEN_BY_YOU
			else:
				username = logic_slot.occupier
				take_leave_button_state = \
					BattlePlayerSlotPanel.TakeLeaveButtonState.TAKEN_BY_OTHER
		else:
			ui_slot.button_ai.text = "AI"
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

func cycle_ai_slot(slot : BattlePlayerSlotPanel, _backwards : bool):
	if NET.client:
		return
	var index : int = slot_to_index(slot)
	if not IM.game_setup_info.has_slot(index):
		push_error("cycle_ai_slot no slot on index", index)
		return
	var logic_slot = IM.game_setup_info.slots[index]
	if logic_slot.is_bot():
		logic_slot.occupier = ""
	else:
		logic_slot.occupier = 1
	refresh_slot(index)
	if NET.server:
		NET.server.broadcast_full_game_setup(IM.game_setup_info)


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


func fill_presets_list():
	var presets = FileSystemHelpers.list_files_in_folder(CFG.BATTLE_PRESETS_PATH, true, true)
	presets_list.clear()
	for preset in presets:
		presets_list.add_item(preset.trim_prefix(CFG.BATTLE_PRESETS_PATH))
	if presets.size() > 0:
		_on_preset_list_item_selected(0)


func _on_preset_list_item_selected(index):
	var preset_file = presets_list.get_item_text(index)
	var preset_data : PresetBattle = \
			load(CFG.BATTLE_PRESETS_PATH + "/" + preset_file)
	apply_preset(preset_data)


func apply_preset(preset : PresetBattle):
	var map_name = preset.battle_map.resource_path.get_file()
	for i in range(maps_list.item_count):
		if maps_list.get_item_text(i) == map_name:
			maps_list.select(i)
			_on_map_list_item_selected(i)
	for player_idx in preset.armies.size():
		var army = preset.armies[player_idx]
		player_slot_panels[player_idx].apply_army_preset(army)

	if NET.server:
		NET.server.broadcast_full_game_setup(IM.game_setup_info)


func _on_map_list_item_selected(index):
	var map_name = maps_list.get_item_text(index)
	var map = load(CFG.BATTLE_MAPS_PATH + "/" + map_name)
	IM.game_setup_info.battle_map = map
	if NET.server:
		NET.server.broadcast_full_game_setup(IM.game_setup_info)
