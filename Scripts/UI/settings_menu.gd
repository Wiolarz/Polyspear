extends Control

var connected_nodes := {}


func _ready():
	UI.update_settings.connect(refresh)


func refresh():
	_refresh_toggle($VBoxContainer/ToggleAutoStart, "autostart_map")
	_refresh_toggle($VBoxContainer/ToggleBattleDefault, "use_default_battle")
	_refresh_toggle($VBoxContainer/ToggleDefaultAIPlayers, "use_default_AI_players")
	_refresh_toggle($VBoxContainer/ToggleFullscreen, "fullscreen")
	_refresh_toggle($VBoxContainer/ToggleBMFastIntegrityChecks, "bmfast_integrity_checks")



func _refresh_toggle(node : CheckButton, option: StringName):
	node.button_pressed = CFG.player_options.get(option)
	if node not in connected_nodes:
		connected_nodes[node] = true
		node.pressed.connect(_toggle_option.bind(node, option))


func _toggle_option(node : CheckButton, option: StringName):
	var old_option = CFG.player_options.get(option)
	CFG.player_options.set(option, not old_option)
	CFG.save_player_options()
	UI.update_settings.emit()


func _on_toggle_auto_start_visibility_changed():
	if visible:
		refresh()


func _on_toggle_streamer_mode_pressed():
	CFG.player_options.streamer_mode = not CFG.player_options.streamer_mode
	CFG.save_player_options()
	$VBoxContainer/ToggleStreamerMode.button_pressed = CFG.player_options.streamer_mode
