class_name WorldPlayerSlotPanel
extends PanelContainer

enum TakeLeaveButtonState {
	FREE,
	TAKEN_BY_YOU,
	TAKEN_BY_OTHER,
	GHOST, # state when we display too much slots
}

var setup_ui = null # TODO some base class for BattleSetup and WorldSetup
var button_take_leave_state : TakeLeaveButtonState = TakeLeaveButtonState.FREE

@onready var button_take_leave = $HBoxContainer/ButtonTakeLeave
@onready var label_name = $HBoxContainer/PlayerInfoPanel/Label
@onready var button_race = $HBoxContainer/ButtonRace

func try_to_take():
	if not setup_ui:
		return
	setup_ui.try_to_take_slot(self)


func try_to_leave():
	if not setup_ui:
		return
	setup_ui.try_to_leave_slot(self)


func cycle_color(backwards : bool = false):
	if not setup_ui:
		return
	setup_ui.cycle_color_slot(self, backwards)


func cycle_race(backwards : bool = false):
	if not setup_ui:
		return
	setup_ui.cycle_race_slot(self, backwards)


func set_visible_color(c : Color):
	var style_box = get_theme_stylebox("panel")
	if not style_box is StyleBoxFlat:
		return
	var style_box_flat = style_box as StyleBoxFlat
	style_box_flat.bg_color = c


func set_visible_name(player_name : String):
	label_name.text = player_name


func set_visible_take_leave_button_state(state : TakeLeaveButtonState):
	# maybe better get this from battle setup, but this is simpler
	button_take_leave_state = state
	match state:
		TakeLeaveButtonState.FREE:
			button_take_leave.text = "Take"
			button_take_leave.disabled = false
		TakeLeaveButtonState.TAKEN_BY_YOU:
			button_take_leave.text = "Leave"
			button_take_leave.disabled = false
		TakeLeaveButtonState.TAKEN_BY_OTHER:
			if IM.is_slot_steal_allowed():
				button_take_leave.text = "Steal"
				button_take_leave.disabled = false
			else:
				# ">> TAKEN <<" -- simple "Taken" would be too similar to "Take"
				button_take_leave.text = ">> TAKEN <<"
				button_take_leave.disabled = true
		TakeLeaveButtonState.GHOST:
			button_take_leave.text = "ghost"
			button_take_leave.disabled = true


func set_visible_race(race : DataRace):
	if race == null:
		button_race.text = "nobody"
		return
	button_race.text = race.race_name


func _on_button_take_leave_pressed():
	match button_take_leave_state:
		TakeLeaveButtonState.FREE:
			try_to_take()
		TakeLeaveButtonState.TAKEN_BY_YOU:
			try_to_leave()
		TakeLeaveButtonState.TAKEN_BY_OTHER:
			if IM.is_slot_steal_allowed():
				try_to_take()


func _on_button_color_pressed():
	cycle_color()


func _on_button_race_pressed():
	cycle_race()
