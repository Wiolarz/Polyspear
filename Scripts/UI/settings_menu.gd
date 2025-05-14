extends Control

## Refer to player_controls.gd for information on adding new settings

func _ready():
	# You should put all PlayerOptions-widget connections here
	_declare_toggle("autostart_map", $ToggleAutoStart)
	_declare_toggle("use_default_AI_players", $ToggleDefaultAIPlayers)
	_declare_toggle("streamer_mode", $ToggleStreamerMode)
	_declare_toggle("fullscreen", $ToggleFullscreen)
	_declare_toggle("bmfast_integrity_checks", $ToggleBMFastIntegrityChecks)
	_declare_toggle("background_color_follows_players", $ToggleBackgroundColorFollowsPlayers)
	_declare_enum_list("gui_animation_mode", $OptionGuiAnimationMode/Option, {
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
	
	# Refresh button visuals when a setting is changed
	UI.update_settings.connect(func(): 
		# Lambda instead of bind because one callable can be only bound to signal once
		node.button_pressed = CFG.player_options.get(option)
	)
	
	# Bind a toggle press
	node.pressed.connect(func():
		# This one could be a dedicated func, but for consistency let's keep it that way
		var old_option = CFG.player_options.get(option)
		CFG.player_options.set(option, not old_option)
		CFG.save_player_options()
		UI.update_settings.emit()
	)

#endregion - Toggle


#region - Enum List

## Connect enum variable to an option button
func _declare_enum_list(enum_var : StringName, node : OptionButton, value_mappings : Dictionary):
	var id_enum_mappings := {}
	var enum_id_mappings := {}
	
	var c := -1
	for enum_item in value_mappings:
		c += 1
		node.add_item(value_mappings[enum_item])
		id_enum_mappings[c] = enum_item
		enum_id_mappings[enum_item] = c
	
	node.selected = enum_id_mappings[CFG.player_options.get(enum_var)]
	
	# Refresh visuals when a setting is changed
	UI.update_settings.connect(func(): 
		# Lambda instead of bind because one callable can be only bound to signal once
		var enum_value = CFG.player_options.get(enum_var)
		node.selected = enum_id_mappings[enum_value]
	)
	
	# Bind an item select
	node.item_selected.connect(func(index : int):
		CFG.player_options.set(enum_var, id_enum_mappings[index])
		CFG.save_player_options()
		UI.update_settings.emit()
	)


#endregion - Enum List
#endregion Widgets

