extends CanvasLayer

func _on_back_to_game_pressed():
	IM.hide_in_game_menu()


func _on_full_screen_pressed():
	IM.toggle_fullscreen()


func _on_quit_pressed():
	IM.quit_game()


func _on_win_battle_pressed():
	BM.force_win_battle()
	IM.hide_in_game_menu()


func _on_surrender_pressed():
	BM.force_surrender()
	IM.hide_in_game_menu()


func _on_return_to_main_menu_pressed():
	IM.hide_in_game_menu()
	IM.go_to_main_menu()

