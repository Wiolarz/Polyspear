# Lobby

## Relevant files

### UI:

`ui_manager.gd`

#### UI/Lobby :

`game_setup.gd`

`battle_setup.gd`

`battle_player_slot_panel.gd`

### General:

`input_manager.gd`

`Game_setup_info.gd`

  

## Description

Everything starts with a `_ready()`: from `game_setup.gd` depending on the setting it either starts:

`_on_button_battle_pressed()` or `_on_button_world_pressed()`

which mainly influences: `IM.game_setup_info.game_mode` And in terms of UI launches: `_select_setup_page(selected_UI_scene)`

  

# Game mode neutral

`_prepare_to_start_game()` It’s always launched without arguments

# Battle map

  

# World map
