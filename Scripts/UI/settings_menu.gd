extends Control


func _ready():
	# You should put all PlayerOptions-widget connections here
	_declare_toggle("autostart_map", $VBoxContainer/ToggleAutoStart)
	_declare_toggle("use_default_battle", $VBoxContainer/ToggleBattleDefault)
	_declare_toggle("use_default_AI_players", $VBoxContainer/ToggleDefaultAIPlayers)
	_declare_toggle("streamer_mode", $VBoxContainer/ToggleStreamerMode)
	_declare_toggle("fullscreen", $VBoxContainer/ToggleFullscreen)
	_declare_toggle("bmfast_integrity_checks", $VBoxContainer/ToggleBMFastIntegrityChecks)


#region Widgets
#region - Toggle

## Connect a given option with a widget
func _declare_toggle(option : StringName, node : CheckButton):
	# Immediately update option
	node.button_pressed = CFG.player_options.get(option)
	# Refresh when a setting is changed
	UI.update_settings.connect(func(): 
		# Lambda instead of bind because one callable can be only bound to signal once
		node.button_pressed = CFG.player_options.get(option)
	)
	# Bind a toggle press
	node.pressed.connect(_toggle_option.bind(option, node))


func _toggle_option(option: StringName, node : CheckButton):
	var old_option = CFG.player_options.get(option)
	CFG.player_options.set(option, not old_option)
	CFG.save_player_options()
	UI.update_settings.emit()

#endregion - Toggle
#endregion Widgets
