extends CanvasLayer

@export var game_setup : GameSetup
@export var test_battle_setup : BattleSetup

@export var players : Array[Player]
@export var world_map : WorldMap


func _on_test_game_pressed():
    if game_setup == null:
        print("No game setup")
        return
    
    players = []
    for player_set in game_setup.player_settings:
        var player = Player.generate_player(player_set)
        players.append(player)

    world_map = game_setup.world_map

    start_game()

func start_game():
    toggle_menu_visibility()
    WM.start_world(players, game_setup.world_map)

func toggle_menu_visibility():
    visible = not visible


func _on_test_battle_pressed():
    
    if test_battle_setup == null:
        print("No battle setup")
        return
    
    players = []
    for player_set in test_battle_setup.player_settings:
        var player = Player.generate_player(player_set)
        players.append(player)
    IM.players = players

    
    var new_armies : Array[Army] = []
    for i in range(test_battle_setup.armies.size()):
        var new_army = Army.new()
        new_army.unit_set = test_battle_setup.armies[i]
        new_army.controller = players[i]
        new_armies.append(new_army)

    toggle_menu_visibility()
    BM.start_battle(new_armies, test_battle_setup.battle_map)
