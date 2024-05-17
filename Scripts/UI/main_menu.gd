extends CanvasLayer


func _init():
	BattleReplay.prepare_replay_directory()


func _ready():
	refresh_replays_disabled()
	if CFG.AUTO_START_GAME:
		await get_tree().create_timer(0.1).timeout  # Waits for the Main menu UI to properly load, so it can be closed
		IM.start_game()


func refresh_replays_disabled():
	$MainContainer/TopMenu/ReplaysMenuBar/Replays.set_item_disabled(0, not BattleReplay.has_replays())


func _on_replays_id_pressed(_id):
	$FileDialogReplay.show()


func _on_file_dialog_replay_file_selected(path):
	IM.perform_replay(path)


func _on_editors_menu_id_pressed(id):
	match id:
		0: IM.go_to_map_editor()
		1: UI.go_to_unit_editor()
		_: pass


func _on_visibility_changed():
	refresh_replays_disabled()


func _on_multiplayer_id_pressed(id):
	match id:
		0:
			$MainContainer/HostLobby.show()
			$MainContainer/ClientLobby.hide()
			$MainContainer/SettingsMenu.hide()
		1:
			$MainContainer/HostLobby.hide()
			$MainContainer/ClientLobby.show()
			$MainContainer/SettingsMenu.hide()
		_: pass


func _on_settings_button_pressed():
	$MainContainer/HostLobby.hide()
	$MainContainer/ClientLobby.hide()
	$MainContainer/SettingsMenu.show()
