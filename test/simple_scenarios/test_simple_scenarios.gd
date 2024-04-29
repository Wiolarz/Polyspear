extends GutTest

func before_all():
	gut.p("INIT - go to main menu (as MainScene does)")
	IM.go_to_main_menu()

func after_all():
	gut.p("INIT - hide main menu (restore state)")
	UI._hide_all()

func test_map_start_and_close() -> void:
	gut.p("click 'Start Game' in main menu")
	var start_game_button = $"/root/UI/MainMenu/Control/VBoxContainer/Host"
	assert_true( start_game_button.is_visible_in_tree(), \
		"Start Game button not visible")
	start_game_button.pressed.emit()

	gut.p("click 'Full game' in lobby")
	var full_game_button = $"/root/UI/HostLobby/HostMenu/PanelContainer/MultiGameSetup/MarginContainer/VBoxContainer/ModeChoice/ButtonFullScenario"
	assert_true( full_game_button.is_visible_in_tree(), \
		"Full Game button not visible")
	full_game_button.toggled.emit(true)

	gut.p("click 'Start' button in lobby")
	var lobby_start_button = $/root/UI/HostLobby/HostMenu/PanelContainer/MultiGameSetup/MarginContainer/VBoxContainer/ButtonConfirm
	assert_true( lobby_start_button.is_visible_in_tree(), \
		"Lobby Start button not visible")
	lobby_start_button.pressed.emit()

	gut.p("simple check if map loaded correctly")
	var world_ui = $/root/UI/WorldUi
	assert_is(world_ui, CanvasLayer, "World UI not a CanvasLayer")
	assert_true(world_ui.visible, "World UI not visible")
	assert_eq(W_GRID.get_child_count(),14*10, "Map spawned, but tiles count not 14*10")
	assert_is(W_GRID.get_child(0), HexTile, "Map spawned, but tiles are not HexTile")

	gut.p("open in game menu")
	var open_menu_button = $/root/UI/WorldUi/Menu
	open_menu_button.pressed.emit()

	var in_game_menu = $/root/UI/InGameMenu
	assert_true(in_game_menu.visible, "In game menu not visible")

	gut.p("press 'back to main menu' button")
	var quit_to_main_button =  $/root/UI/InGameMenu/MenuContainer/ReturnToMainMenu
	assert_true(quit_to_main_button.is_visible_in_tree(), \
		"back to main menu button not visible")

	quit_to_main_button.pressed.emit()
	await wait_frames(1) # wait for queue_free

	gut.p("check that main menu looks ok")
	assert_false(world_ui.visible, "World UI still visible")
	assert_eq(W_GRID.get_child_count(), 0, "Map should be cleared")
	assert_true( $"/root/UI/MainMenu".visible, \
		"main menu is not visible")
	assert_true( start_game_button.is_visible_in_tree(), \
		"Start Game button is not visible")
