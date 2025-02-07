extends CanvasLayer


func _on_back_to_game_pressed():
	IM.toggle_in_game_menu()


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


func _on_visibility_changed():
	$SettingsModal.visible = false


func _on_settings_pressed():
	$SettingsModal.visible = true


func _on_settings_exit_pressed():
	$SettingsModal.visible = false
