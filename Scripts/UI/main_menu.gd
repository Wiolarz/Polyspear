extends CanvasLayer


func _init():
	BattleReplay.prepare_replay_directory()


func _ready():
	refresh_replays_disabled()
	if CFG.AUTO_START_GAME:
		await get_tree().create_timer(0.1).timeout  # Waits for the Main menu UI to properly load, so it can be closed
		IM.start_new_game()


func refresh_replays_disabled():
	($MainContainer/TopMenu/Tabs as TabBar).set_tab_disabled(4, not BattleReplay.has_replays())


func _on_visibility_changed():
	refresh_replays_disabled()


func _on_host_button_pressed():
	_clear_tabs()
	$MainContainer/HostLobby.show()


func _on_join_button_pressed():
	_clear_tabs()
	$MainContainer/ClientLobby.show()


func _on_settings_button_pressed():
	_clear_tabs()
	$MainContainer/SettingsMenu.show()


func _on_credits_button_pressed():
	_clear_tabs()
	$MainContainer/CreditsMenu.show()

func _on_replays_tab_pressed():
	_clear_tabs()
	$MainContainer/ReplaysMenu.show()


func _clear_tabs():
	$MainContainer/HostLobby.hide()
	$MainContainer/ClientLobby.hide()
	$MainContainer/SettingsMenu.hide()
	$MainContainer/CreditsMenu.hide()
	$MainContainer/ReplaysMenu.hide()


func _on_unit_editor_button_pressed():
	UI.go_to_unit_editor()


func _on_map_editor_button_pressed():
	IM.go_to_map_editor()


func _on_exit_button_pressed():
	get_tree().quit()


func _on_tabs_tab_changed(tab_index:int):
	match tab_index:
		0: _on_host_button_pressed()
		1: _on_join_button_pressed()
		2: _on_settings_button_pressed()
		3: _on_credits_button_pressed()
		4: _on_replays_tab_pressed()
		_: push_error("_on_tabs_tab_changed index not supported: "+str(tab_index))
