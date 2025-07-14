extends GutTest

const DEFAULT_MAP_TILES_COUNT = 35  # classic 5x5 == 23 + 13 sentinels

func before_all():
	gut.p("INIT - go to main menu (as MainScene does)")
	CFG.AUTO_START_GAME = false # disable autostart cheat
	IM.go_to_main_menu()


func after_all():
	gut.p("INIT - hide main menu (restore state)")
	UI._hide_all()


func start_classic_battle_map() -> void:
	var full_game_button = get_node(test_UI_PATHS.BATTLE_MODE_BUTTON_PATH)
	full_game_button.pressed.emit()  # click 'Custom Battle' in lobby

	# TODO: stabilize default map so that this test doesnt need to be updated
	# when new map is added and happens to be picked as first

	var lobby_start_button = get_node(test_UI_PATHS.START_GAME_BUTTON_PATH)
	lobby_start_button.pressed.emit()  # click 'Start' button in lobby

func exit_battle_map() -> void:

	while not BM.battle_is_active():
		var continue_node : Button = get_node("/root/UI/UIOverlay/Container/Summary/VBoxContainer/ButtonContinue")
		await wait_frames(1)
		if continue_node:
			continue_node.pressed.emit()
			return



	var open_menu_button = get_node(test_UI_PATHS.OPEN_IN_GAME_MENU_PATH)
	open_menu_button.pressed.emit()  # "open in game menu"

	var in_game_menu = get_node(test_UI_PATHS.IN_GAME_MENU_PATH)

	var quit_to_main_button =  get_node(test_UI_PATHS.IN_GAME_MENU_BACK_TO_MAIN_MENU_PATH)

	quit_to_main_button.pressed.emit() # press 'back to main menu' button
	await wait_frames(1) # wait for queue_free


func test_map_start_and_close() -> void:
	gut.p("click 'Custom Battle' in lobby")
	var full_game_button = get_node(test_UI_PATHS.BATTLE_MODE_BUTTON_PATH)
	assert_true( full_game_button.is_visible_in_tree(), \
		"Full Game button not visible")
	full_game_button.pressed.emit()

	gut.p("click 'Start' button in lobby")
	var lobby_start_button = get_node(test_UI_PATHS.START_GAME_BUTTON_PATH)
	assert_true( lobby_start_button.is_visible_in_tree(), \
		"Lobby Start button not visible")
	lobby_start_button.pressed.emit()

	gut.p("simple check if map loaded correctly")
	var battle_ui = get_node(test_UI_PATHS.Battle_UI_PATH)
	assert_is(battle_ui, CanvasLayer, "Battle UI not a CanvasLayer")
	assert_true(battle_ui.visible, "Battle UI not visible")
	# TODO: stabilize default map so that this test doesnt need to be updated
	# when new map is added and happens to be picked as first
	assert_eq(BM.get_node("GRID").get_child_count(), DEFAULT_MAP_TILES_COUNT, \
		"Map spawned, but tiles count is not 23")
	assert_is(BM.get_node("GRID").get_child(0), TileForm, "Map spawned, but tiles are not TileForm")

	gut.p("open in game menu")
	var open_menu_button = get_node(test_UI_PATHS.OPEN_IN_GAME_MENU_PATH)
	open_menu_button.pressed.emit()

	var in_game_menu = get_node(test_UI_PATHS.IN_GAME_MENU_PATH)
	assert_true(in_game_menu.visible, "In game menu not visible")

	gut.p("press 'back to main menu' button")
	var quit_to_main_button =  get_node(test_UI_PATHS.IN_GAME_MENU_BACK_TO_MAIN_MENU_PATH)
	assert_true(quit_to_main_button.is_visible_in_tree(), \
		"back to main menu button not visible")

	quit_to_main_button.pressed.emit()
	await wait_frames(1) # wait for queue_free

	gut.p("check that main menu looks ok")
	assert_false(battle_ui.visible, "Battle UI still visible")
	assert_eq(WM.get_node("GRID").get_child_count(), 0, "Map should be cleared")
	assert_true( get_node(test_UI_PATHS.MAIN_MENU_UI_PATH).visible, \
		"main menu is not visible")
	assert_true( get_node(test_UI_PATHS.START_GAME_BUTTON_PATH).is_visible_in_tree(), \
		"Start Game button is not visible")


func test_random_battle_moves() -> void:
	start_classic_battle_map()
	var new_button_press_event = InputEventAction.new()
	new_button_press_event.action = "AI_MOVE"
	new_button_press_event.pressed = true

	while BM.battle_is_active():
		Input.parse_input_event(new_button_press_event)
		await wait_frames(15)

	exit_battle_map()

