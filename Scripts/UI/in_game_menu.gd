extends CanvasLayer


func _ready():
	$MenuContainer/ToggleAutoStart.button_pressed = CFG.AUTO_START_GAME
	$MenuContainer/ToggleBattleDefault.button_pressed = CFG.DEFAULT_MODE_IS_BATTLE


func refresh():
	$MenuContainer/ToggleAutoStart.button_pressed = CFG.AUTO_START_GAME
	$MenuContainer/ToggleBattleDefault.button_pressed = CFG.DEFAULT_MODE_IS_BATTLE


func _on_back_to_game_pressed():
	IM.toggle_in_game_menu()


func _on_full_screen_pressed():
	IM.toggle_fullscreen()


func _on_quit_pressed():
	IM.quit_game()


func _on_win_battle_pressed():
	BM.force_win_battle()
	IM.toggle_in_game_menu()


func _on_surrender_pressed():
	BM.force_surrender()
	IM.toggle_in_game_menu()


func _on_return_to_main_menu_pressed():
	IM.toggle_in_game_menu()
	IM.go_to_main_menu()



func _on_toggle_auto_start_pressed():
	CFG.player_options.autostart_map = not CFG.player_options.autostart_map
	CFG.save_player_options()
	$MenuContainer/ToggleAutoStart.button_pressed = CFG.AUTO_START_GAME


func _on_toggle_battle_default_pressed():
	CFG.player_options.use_default_battle = not CFG.player_options.use_default_battle
	CFG.save_player_options()
	$MenuContainer/ToggleBattleDefault.button_pressed = CFG.DEFAULT_MODE_IS_BATTLE


func _on_visibility_changed():
	if visible:
		refresh()
