extends Control


@onready var main_container = $Margin/VBox

@onready var toggle_auto_start = main_container.get_node("ToggleAutoStart")
@onready var toggle_battle_default = main_container.get_node("ToggleBattleDefault")
@onready var toggle_default_ai_players = main_container.get_node("ToggleDefaultAIPlayers")
@onready var toggle_streamer_mode = main_container.get_node("ToggleStreamerMode")
@onready var toggle_fullscreen = main_container.get_node("ToggleFullscreen")
@onready var toggle_bmfast_integrity_checks = main_container.get_node("ToggleBMFastIntegrityChecks")
@onready var toggle_background_color_follows_players = \
	main_container.get_node("ToggleBackgroundColorFollowsPlayers")

@onready var option_gui_anim_mode : Button = main_container.get_node("OptionGuiAnimationMode/Option")

func _ready():
	# You should put all PlayerOptions-widget connections here
	_declare_toggle("autostart_map", toggle_auto_start)
	_declare_toggle("use_default_battle", toggle_battle_default)
	_declare_toggle("use_default_AI_players", toggle_default_ai_players)
	_declare_toggle("streamer_mode", toggle_streamer_mode)
	_declare_toggle("fullscreen", toggle_fullscreen)
	_declare_toggle("bmfast_integrity_checks", toggle_bmfast_integrity_checks)
	_declare_toggle("background_color_follows_players", toggle_background_color_follows_players)
	_declare_enum_list("gui_animation_mode", option_gui_anim_mode, {
		CFG.GuiAnimationMode.NONE: "None",
		CFG.GuiAnimationMode.NON_DISTRACTION: "Only non-distracting",
		CFG.GuiAnimationMode.FULL: "All"
	})

#region Widgets
#region - Toggle

## Connect a given option with a widget
## Use as a template for other widgets
func _declare_toggle(option : StringName, node : CheckBox):
	# Immediately update option
	node.button_pressed = CFG.player_options.get(option)
	# Refresh when a setting is changed
	UI.update_settings.connect(func(): 
		# Lambda instead of bind because one callable can be only bound to signal once
		node.button_pressed = CFG.player_options.get(option)
	)
	# Bind a toggle press
	node.pressed.connect(_toggle_option.bind(option))


func _toggle_option(option: StringName):
	var old_option = CFG.player_options.get(option)
	CFG.player_options.set(option, not old_option)
	CFG.save_player_options()
	UI.update_settings.emit()

#endregion - Toggle

#region - Enum List

## Connect enum variable to an option button
func _declare_enum_list(enum_var : StringName, node : OptionButton, value_mappings : Dictionary):
	var id_enum_mappings := {}
	var enum_id_mappings := {}
	
	var c = -1
	for enum_item in value_mappings:
		c += 1
		node.add_item(value_mappings[enum_item])
		id_enum_mappings[c] = enum_item
		enum_id_mappings[enum_item] = c
	
	node.selected = enum_id_mappings[CFG.player_options.get(enum_var)]
	
	# Refresh when a setting is changed
	UI.update_settings.connect(func(): 
		# Lambda instead of bind because one callable can be only bound to signal once
		var enum_value = CFG.player_options.get(enum_var)
		node.selected = enum_id_mappings[enum_value]
	)
	# Bind an item select
	node.item_selected.connect(
		_set_enum_list.bind(enum_var, id_enum_mappings)
	)


func _set_enum_list(
	index: int, # item_selected signal parameter
	enum_var: StringName, id_enum_mappings : Dictionary
):
	CFG.player_options.set(enum_var, id_enum_mappings[index])
	CFG.save_player_options()
	UI.update_settings.emit()

#endregion - Enum List
#endregion Widgets
