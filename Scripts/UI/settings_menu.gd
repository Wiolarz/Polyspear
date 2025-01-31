extends Control


@onready var main_container = $Margin/VBox

@onready var toggle_auto_start = main_container.get_node("ToggleAutoStart")
@onready var toggle_battle_default = main_container.get_node("ToggleBattleDefault")
@onready var toggle_default_ai_players = main_container.get_node("ToggleDefaultAIPlayers")
@onready var toggle_streamer_mode = main_container.get_node("ToggleStreamerMode")
@onready var toggle_background_color_follows_players = \
	main_container.get_node("ToggleBackgroundColorFollowsPlayers")


func refresh():
	toggle_auto_start.button_pressed = CFG.AUTO_START_GAME
	toggle_battle_default.button_pressed = CFG.DEFAULT_MODE_IS_BATTLE
	toggle_default_ai_players.button_pressed = CFG.player_options.use_default_AI_players
	toggle_streamer_mode.button_pressed = CFG.player_options.streamer_mode


func _on_toggle_auto_start_pressed():
	# TODO refactor code copying
	CFG.player_options.autostart_map = not CFG.player_options.autostart_map
	CFG.save_player_options()
	toggle_auto_start.button_pressed = CFG.AUTO_START_GAME


func _on_toggle_battle_default_pressed():
	CFG.player_options.use_default_battle = not CFG.player_options.use_default_battle
	CFG.save_player_options()
	toggle_battle_default.button_pressed = CFG.DEFAULT_MODE_IS_BATTLE


func _on_toggle_background_color_follows_players():
	CFG.player_options.background_color_follows_players = \
		not CFG.player_options.background_color_follows_players
	CFG.save_player_options()
	toggle_background_color_follows_players.button_pressed = \
		CFG.player_options.background_color_follows_players


func _on_toggle_auto_start_visibility_changed():
	if visible:
		refresh()


func _on_toggle_default_ai_players_pressed():
	#TODO quick refactor
	CFG.player_options.use_default_AI_players = not CFG.player_options.use_default_AI_players
	CFG.save_player_options()
	toggle_default_ai_players.button_pressed = CFG.player_options.use_default_AI_players


func _on_toggle_streamer_mode_pressed():
	CFG.player_options.streamer_mode = not CFG.player_options.streamer_mode
	CFG.save_player_options()
	toggle_streamer_mode.button_pressed = CFG.player_options.streamer_mode

