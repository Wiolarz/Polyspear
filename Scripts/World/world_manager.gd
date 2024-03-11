extends Node

#region Setup Parameters
"""
Current simplifications:
1 All players are host-seat
2 Basic same map
3 Same game parameters set as const

"""

var players : Array[Player] = []

#endregion


""" grid
contains:
    Places - Resource node /+ Neutral camp
    Cities
    Terrain blocks
    Sentinels
"""



#region Variables

var grid : Array = [] #Array[Array[]]

# conatins all positions of the heroes around the map
var hero_grid : Array = [] # Array[Array[Hero]]




var current_player : Player

var selected_hero

#endregion


#region Main functions

func setup_world(): #(players, map, settings)
    """
    Currently empty as all test settings are set already
    """
    current_player = players[0]

func clear_level():
    for hero in get_children():
        hero.queue_free()
    for tile in W_GRID.get_children():
        tile.queue_free()


func next_player_turn():
    var player_idx = players.find(current_player)
    if player_idx + 1 == players.size():
        current_player = players[0]
    else:
        current_player = players[player_idx + 1]


#endregion

#region Tools



#endregion

#region Player Actions

func grid_input(cord : Vector2i):
    """
    What can happen:
    I Scenario - player doesn't have any hero selected:
        1 Selects empty/enemy spot -> return
        2 Selects ally hero -> set selected hero then return
        3 Select ally city -> show interface then return
    II Scenario - player has a hero selected
        1 Selects empty/enemy/ally city/ally hero spot -> move_hero()
        2 Selects the same hero -> unselect current hero



    Can:
        1 select new hero
        2 choose a legal tile to move a selected hero to
        3 choose a city
        4 if a hero is inside a city, a special interface will apear (either it simply selects the hero inside the city, then you can close the interaface and move freely)
        5 player selected trade interface between heroes
    """

    if select_city(cord) or select_hero(cord) or selected_hero == null:
        return

    move_hero(cord)



func select_city(cord : Vector2i) -> bool:
    """
    """
    var city = W_GRID.get_city(cord)

    if city == null or city.controller != current_player:
        return false
    
    city.show_interface()
    return true

func select_hero(cord : Vector2i) -> bool:
    """
    What can happen:
    I Scenario - player doesn't have any hero selected:
        1 Selects empty/enemy spot -> return false
        2 Selects ally hero -> set hero then return true
    II Scenario - player has a hero selected
        1 Selects the same hero  -> unselect current hero return true/false(no difference)
        2 Selects another ally hero -> return false

        
    
    """
    # TODO test unselect/no unselect on double click and determine which is more intuitive for most playersc

    var new_hero = W_GRID.get_hero(cord)
    if new_hero == null:
        return false
    
    if new_hero == selected_hero:
        selected_hero = null
        return true

    if new_hero.controller == current_player:
        selected_hero = new_hero
        return true

    return false


func is_enemy_present(cord : Vector2i):
    if W_GRID.get_tile_controller(cord) == current_player:
        return false
    if W_GRID.get_army(cord) == null:
        return false 
    return true

func move_hero(cord : Vector2i):
    # moves the currently selected hero
    """
    1 Check if the destination is a valid target (not a wall)
    2 Check if a tile is next to a hero
    3 Check if tile is occupied with ally hero (open trade menu return)
    4 if a tile is ally city enter and open city interface return
    5 if a tile is combat (start a battle, depending on the result either move the hero or remove him)
    6 move a hero to an open spot
    """

    if not W_GRID.is_moveable(cord):
        return
    
    if not W_GRID.is_adjacent(selected_hero.cord, cord):
        return

    var new_hero = W_GRID.get_hero(cord)
    if new_hero != null and new_hero.controller == current_player:
        selected_hero.trade(new_hero)
        return
    

    var city = W_GRID.get_city(cord)

    if city != null and city.controller == current_player:
        W_GRID.change_hero_position(selected_hero, cord)
        city.show_interface()
        return
    

    if is_enemy_present(cord):
        if combat(cord):
            print("you won")
            #clear the tile of enemy presence
            W_GRID.change_hero_position(selected_hero, cord)
            return
        
        else:
            print("hero died")
            return

    W_GRID.change_hero_position(selected_hero, cord)

func combat(cord : Vector2i) -> bool:
    print("combat")
    return true