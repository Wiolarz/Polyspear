extends CanvasLayer

@export var game_setup : GameSetup
@export var test_battle_setup : GameSetup

@export var players : Array[Player]
@export var world_map : WorldMap


@onready var ui = $".."

func _on_test_game_pressed():
    if game_setup == null:
        print("No game setup")
        return
    
    players = []
    for player_set in game_setup.player_settings:
        var player = Player.new()
        player.player_type = player_set.player_type
        player.faction = player_set.faction
        players.append(player)

    world_map = game_setup.world_map

    start_game()

func start_game():
    toggle_menu_visibility()
    WM.start_world(players, game_setup.world_map)

func toggle_menu_visibility():
    ui.visible = not ui.visible


func _on_test_battle_pressed():
    
	if game_setup == null:
        print("No game setup")
        return
    
    players = []
    for player_set in game_setup.player_settings:
        var player = Player.new()
        player.player_type = player_set.player_type
        player.faction = player_set.faction
        players.append(player)

    world_map = game_setup.world_map

    start_game()
