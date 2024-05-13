extends Control


func refresh():
	$VBoxContainer/ToggleAutoStart.button_pressed = CFG.AUTO_START_GAME
	$VBoxContainer/ToggleBattleDefault.button_pressed = CFG.DEFAULT_MODE_IS_BATTLE


func _on_toggle_auto_start_pressed():
	# TODO refactor code copying
	CFG.player_options.autostart_map = not CFG.player_options.autostart_map
	CFG.save_player_options()
	$VBoxContainer/ToggleAutoStart.button_pressed = CFG.AUTO_START_GAME


func _on_toggle_battle_default_pressed():
	CFG.player_options.use_default_battle = not CFG.player_options.use_default_battle
	CFG.save_player_options()
	$VBoxContainer/ToggleBattleDefault.button_pressed = CFG.DEFAULT_MODE_IS_BATTLE


func _on_toggle_auto_start_visibility_changed():
	if visible:
		refresh()
