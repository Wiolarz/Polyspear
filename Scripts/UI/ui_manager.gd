# Singleton - UI
extends Node

var in_game_menu
var main_menu
var ui_overlay
var map_editor
var unit_editor
var tile_editor
var host_lobby
var client_lobby
var hero_level_up

var camera : PolyCamera
var current_camera_position = E.CameraPosition.WORLD

signal update_settings()


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	IM.init_game_setup() # drut

	in_game_menu = load("res://Scenes/UI/GameMenu.tscn").instantiate()
	main_menu    = load("res://Scenes/UI/MainMenu.tscn").instantiate()
	ui_overlay   = load("res://Scenes/UI/UIOverlay.tscn").instantiate()
	map_editor   = load("res://Scenes/UI/Editors/MapEditor.tscn").instantiate()
	unit_editor  = load("res://Scenes/UI/Editors/UnitEditor.tscn").instantiate()
	tile_editor  = load("res://Scenes/UI/Editors/TileEditor.tscn").instantiate()
	hero_level_up = load("res://Scenes/UI/LevelUp/LevelUpScreen.tscn").instantiate()

	add_child(main_menu)
	add_child(map_editor)
	add_child(unit_editor)
	add_child(tile_editor)
	add_child(ui_overlay)
	add_child(hero_level_up)
	add_child(in_game_menu, false, Node.INTERNAL_MODE_BACK)

	_hide_all()


func add_custom_screen(custom_ui : CanvasLayer):
	add_child(custom_ui)
	custom_ui.hide()
	# we need them always at the top
	if ui_overlay:
		move_child(ui_overlay, -1)
	if in_game_menu:
		move_child(in_game_menu, -1)


func go_to_custom_ui(custom_ui : CanvasLayer):
	_hide_all()
	custom_ui.show()


func _hide_all():
	for c in get_children(true):
		c.hide()
	BG.set_default_colors()


func go_to_main_menu():
	_hide_all()
	main_menu.show()


func go_to_unit_editor():
	_hide_all()
	unit_editor.show()
	
func go_to_tile_editor():
	_hide_all()
	tile_editor.show()


## TEMP
func go_to_map_editor():
	_hide_all()
	map_editor.open_draw_menu()
	BG.set_player_colors(CFG.NEUTRAL_COLOR)


## TEMP
func show_hero_level_up():
	hero_level_up.hidden = false
	hero_level_up.show()


func close_hero_level_up():
	hero_level_up.hidden = true
	hero_level_up.hide()


func hide_hero_level_up():
	hero_level_up._on_button_hide_pressed()


func show_in_game_menu():
	in_game_menu.show()


func hide_in_game_menu():
	in_game_menu.hide()


## Toggles visibility of in-game menu \
## Disabled in main menu
func toggle_in_game_menu():
	if main_menu.visible or in_game_menu.visible:
		hide_in_game_menu()
	else:
		show_in_game_menu()


func requests_pause():
	return in_game_menu.visible


#region Input Support


func _process(delta):
	# we do not want to process camera when game is paused
	if camera and not get_tree().paused:
		camera.process_camera(delta)


func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("KEY_EXIT_GAME"):
		IM.quit_game()
	if Input.is_action_just_pressed("KEY_MAXIMIZE_WINDOW"):
		toggle_fullscreen()
	if Input.is_action_just_pressed("KEY_MENU"):
		toggle_in_game_menu()
	if Input.is_action_just_pressed("KEY_DEBUG_COLLISION_SHAPES"):
		toggle_collision_debug()
	if event.is_action_pressed("KEY_BOT_SPEED_SLOW"):
		print("anim speed - slow")
		CFG.animation_speed_frames = CFG.AnimationSpeed.NORMAL
		CFG.bot_speed_frames = CFG.BotSpeed.FREEZE
	elif event.is_action_pressed("KEY_BOT_SPEED_MEDIUM"):
		print("anim speed - medium")
		CFG.animation_speed_frames = CFG.AnimationSpeed.NORMAL
		CFG.bot_speed_frames = CFG.BotSpeed.NORMAL
	elif event.is_action_pressed("KEY_BOT_SPEED_FAST"):
		print("anim speed - fast")
		CFG.animation_speed_frames = CFG.AnimationSpeed.INSTANT
		CFG.bot_speed_frames = CFG.BotSpeed.FAST
	elif Input.is_action_just_pressed("KEY_FORCE_DESYNC"):
		print("forcing desynchronization")
		NET.desync()
	if camera and not get_tree().paused:
		camera.process_input_event(event)


	if event.is_action_pressed("UNDO"):
		BM.undo()
	elif event.is_action_pressed("REDO"):
		BM.redo()
	elif event.is_action_pressed("AI_MOVE"):
		BM.ai_move()

	# if event.is_action_pressed("KEY_SAVE_GAME"):
	# 	print("quick save is not yet supported")

	# if event.is_action_pressed("KEY_LOAD_GAME"):
	# 	print("quick load is not yet supported")


# called from TileForm mouse detection
func grid_input_listener(tile_coord : Vector2i, \
		tile_type : GameSetupInfo.GameMode, mouse_drag : bool):
	#print("tile ", tile_coord)
	if IM.in_map_editor:
		if mouse_drag:
			map_editor.grid_input(tile_coord)
		return

	if mouse_drag:
		return

	if tile_type == GameSetupInfo.GameMode.BATTLE:
		BM.grid_input(tile_coord)
	elif tile_type == GameSetupInfo.GameMode.WORLD:
		WM.grid_input(tile_coord)


# called from TileForm mouse detection
func grid_planning_input_listener(tile_coord : Vector2i, \
		tile_type : GameSetupInfo.GameMode,
		is_it_pressed : bool):
	#print("tile ", tile_coord)

	if not tile_type == GameSetupInfo.GameMode.BATTLE:
		printerr("Support for drawing arrows in different modes isn't supported yet")
		# There are plans for right click to have a different purpouse in World Map
		# drawing could be reanabled there with addition of holding alt
		return

	BM.planning_input(tile_coord, is_it_pressed)




func ensure_camera_is_spawned() -> void:
	if not camera:
		camera = PolyCamera.new()
		camera.name = "PolyCamera"
		add_child(camera)


func switch_camera() -> void:
	if current_camera_position == E.CameraPosition.WORLD:
		if BM.can_show_battla_camera():
			set_camera(E.CameraPosition.BATTLE)
	else:
		if IM.game_setup_info.game_mode == GameSetupInfo.GameMode.WORLD:
			set_camera(E.CameraPosition.WORLD)


func set_camera(pos : E.CameraPosition) -> void:
	current_camera_position = pos
	if pos == E.CameraPosition.BATTLE:
		camera.set_bounds(BM.get_bounds_global_position())
	else :
		camera.set_bounds(WM.get_bounds_global_position())


## NOTE: fullscreen uses old style exclusive fullscreen because of Godot bug
func set_fullscreen(fullscreen: bool):
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		# DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		# TODO: change to borderless when Godot bug is fixed
		# https://github.com/godotengine/godot/issues/63500
		# there is a grey border around the screen
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func toggle_fullscreen():
	# automatically launches set_fullscreen
	CFG.player_options.fullscreen = not CFG.player_options.fullscreen
	CFG.save_player_options()
	update_settings.emit()


## Toggle of default godot Debug tool - visible collision shapes
func toggle_collision_debug():

	var tree := get_tree()
	tree.debug_collisions_hint = not tree.debug_collisions_hint

	# Traverse tree to call queue_redraw on instances of
	# CollisionShape2D and CollisionPolygon2D.
	var node_stack: Array[Node] = [tree.get_root()]
	while not node_stack.is_empty():
		var node: Node = node_stack.pop_back()
		if is_instance_valid(node):
			if node is CollisionShape2D or node is CollisionPolygon2D:
				node.queue_redraw()
			if node is TileMap:
				node.collision_visibility_mode = TileMap.VISIBILITY_MODE_FORCE_HIDE
				node.collision_visibility_mode = TileMap.VISIBILITY_MODE_DEFAULT
			node_stack.append_array(node.get_children())
