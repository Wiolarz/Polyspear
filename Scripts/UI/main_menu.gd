extends CanvasLayer


func _init():
	BattleReplay.prepare_replay_directory()


func _ready():
	refresh_replays_disabled()
	if CFG.AUTO_START_GAME:
		await get_tree().create_timer(0.1).timeout  # Waits for the Main menu UI to properly load, so it can be closed
		IM.start_game()


func refresh_replays_disabled():
	$MainContainer/TopMenu/ReplaysButton.set_disabled(not BattleReplay.has_replays())


func _on_visibility_changed():
	refresh_replays_disabled()


func _on_host_button_pressed():
	_clear_tabs()
	$MainContainer/TopMenu/HostButton.modulate = Color.YELLOW
	$MainContainer/HostLobby.show()


func _on_join_button_pressed():
	_clear_tabs()
	$MainContainer/TopMenu/JoinButton.modulate = Color.YELLOW
	$MainContainer/ClientLobby.show()


func _on_settings_button_pressed():
	_clear_tabs()
	$MainContainer/TopMenu/SettingsButton.modulate = Color.YELLOW
	$MainContainer/SettingsMenu.show()


func _clear_tabs():
	$MainContainer/TopMenu/HostButton.modulate = Color.WHITE
	$MainContainer/TopMenu/JoinButton.modulate = Color.WHITE
	$MainContainer/TopMenu/SettingsButton.modulate = Color.WHITE
	$MainContainer/HostLobby.hide()
	$MainContainer/ClientLobby.hide()
	$MainContainer/SettingsMenu.hide()


func _on_replays_button_pressed():
	$FileDialogReplay.show()


func _on_file_dialog_replay_file_selected(path):
	IM.perform_replay(path)


func _on_unit_editor_button_pressed():
	UI.go_to_unit_editor()


func _on_map_editor_button_pressed():
	IM.go_to_map_editor()


func _on_exit_button_pressed():
	get_tree().quit()
