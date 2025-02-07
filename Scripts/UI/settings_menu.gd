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

@onready var cycle_gui_anim_mode : Button = main_container.get_node("CycleGuiAnimationMode")

func _ready():
	# You should put all PlayerOptions-widget connections here
	_declare_toggle("autostart_map", toggle_auto_start)
	_declare_toggle("use_default_battle", toggle_battle_default)
	_declare_toggle("use_default_AI_players", toggle_default_ai_players)
	_declare_toggle("streamer_mode", toggle_streamer_mode)
	_declare_toggle("fullscreen", toggle_fullscreen)
	_declare_toggle("bmfast_integrity_checks", toggle_bmfast_integrity_checks)
	_declare_toggle("background_color_follows_players", toggle_background_color_follows_players)



func refresh():
	var anim_mode = CFG.player_options.gui_animation_mode
	cycle_gui_anim_mode.text = "GUI animation mode: %s" % (
		"none" if anim_mode == CFG.GuiAnimationMode.NONE else
		"only non-distracting" if \
			anim_mode == CFG.GuiAnimationMode.NON_DISTRACTION else
		"all"
	)


#region Widgets
#region - Toggle

## Connect a given option with a widget
func _declare_toggle(option : StringName, node : CheckBox):
	# Immediately update option
	node.button_pressed = CFG.player_options.get(option)
	# Refresh when a setting is changed
	UI.update_settings.connect(func(): 
		# Lambda instead of bind because one callable can be only bound to signal once
		node.button_pressed = CFG.player_options.get(option)
	)
	# Bind a toggle press
	node.pressed.connect(_toggle_option.bind(option, node))


func _toggle_option(option: StringName, node : CheckBox):
	var old_option = CFG.player_options.get(option)
	CFG.player_options.set(option, not old_option)
	CFG.save_player_options()
	UI.update_settings.emit()

#endregion - Toggle
#endregion Widgets


func _on_cycle_gui_anim_mode_pressed():
	var mode : int = CFG.player_options.gui_animation_mode + 1
	if mode >= CFG.GuiAnimationMode.MAX_:
		mode = CFG.GuiAnimationMode.NONE
	CFG.player_options.gui_animation_mode = mode as CFG.GuiAnimationMode
	refresh()

