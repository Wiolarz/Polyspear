class_name BattlePlayerSlotPanel
extends PanelContainer

enum TakeLeaveButtonState {
	FREE,
	TAKEN_BY_YOU,
	TAKEN_BY_OTHER,
	GHOST, # state when we display too much slots
}

enum AiButtonState {
	HUMAN,
	AI,
}

const EMPTY_UNIT_TEXT = " - empty - "

var setup_ui = null # TODO some base class for MultiBattleSetup and
					# MultiScenarioSetup
var button_take_leave_state : TakeLeaveButtonState = TakeLeaveButtonState.FREE
var button_ai_state : AiButtonState = AiButtonState.HUMAN


@onready var button_take_leave = $VBoxContainer/HBoxContainer/ButtonTakeLeave
@onready var label_name = $VBoxContainer/HBoxContainer/PlayerInfoPanel/Label
@onready var button_ai = $VBoxContainer/HBoxContainer/ButtonAI
@onready var buttons_units : Array[OptionButton] = [
	$VBoxContainer/OptionButtonUnit1,
	$VBoxContainer/OptionButtonUnit2,
	$VBoxContainer/OptionButtonUnit3,
	$VBoxContainer/OptionButtonUnit4,
	$VBoxContainer/OptionButtonUnit5,
]

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


func is_bot() -> bool:
	return button_ai_state == AiButtonState.AI

func cycle_ai(backwards : bool = false):
	var new_state = button_ai_state + (-1 if backwards else 1)
	button_ai_state = wrapi(new_state, 0, AiButtonState.size()) as AiButtonState
	button_ai.text = AiButtonState.keys()[button_ai_state]
	pass


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
			# ">> TAKEN <<" -- simple "Taken" would be too similar to "Take"
			button_take_leave.text = ">> TAKEN <<"
			button_take_leave.disabled = true
		TakeLeaveButtonState.GHOST:
			button_take_leave.text = "ghost"
			button_take_leave.disabled = true


func _ready():
	var unit_paths = TestTools.list_files_in_folder(CFG.UNITS_PATH, true, true)
	for b in buttons_units:
		b.clear()
		b.add_item(EMPTY_UNIT_TEXT)
		for unit_path in unit_paths:
			b.add_item(unit_path.trim_prefix(CFG.UNITS_PATH))


func get_units_data() -> Array[DataUnit]:
	var units :Array[DataUnit] = []
	for ub in buttons_units:
		var text = ub.get_item_text(ub.selected)
		if text != EMPTY_UNIT_TEXT:
			units.append(load(CFG.UNITS_PATH + "/" + text))
	return units

func apply_army_preset(army : PresetArmy):
	var idx = 0
	for u in army.units:
		set_unit(buttons_units[idx], u)
		idx += 1
	while idx < buttons_units.size():
		buttons_units[idx].select(0)
		idx += 1

func set_unit(unit_button : OptionButton, unit : DataUnit):
	for idx in unit_button.item_count:
		if unit.resource_path.ends_with(unit_button.get_item_text(idx)):
			unit_button.select(idx)

func _on_button_take_leave_pressed():
	match button_take_leave_state:
		TakeLeaveButtonState.FREE:
			try_to_take()
		TakeLeaveButtonState.TAKEN_BY_YOU:
			try_to_leave()
		_:
			pass


func _on_button_color_pressed():
	cycle_color()


func _on_button_ai_pressed():
	cycle_ai()
