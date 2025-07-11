class_name PlayerOptions
extends Resource


## How to add settings:
## 1. add an export variable here
## 2. add an appropriate (as in _declare_* functions in settings_menu.gd)
##    control to SettingsMenu.tscn
## 3. add a "_declare_*" call in settings_menu.gd's _ready function,
##    referencing the added control


## once the game is launched it instantly start the game with default lobby values [br]
## depending on "use_default_battle" value starts either World/Battle
@export var autostart_map : bool = false

## Default starting screen when launching a game (autostart_map uses this variable)
@export var use_default_battle : bool = true
## if true all player slots are placed in control of AI controller [br]
## if false all slots are by default controlled by host (human player)
@export var use_default_AI_players : bool = false

## if true, compares BattleGridState and LibSpear's BattleManagerFast
## for mismatches before and after each battle move, activating an assert on mismatch
@export var bmfast_integrity_checks : bool = true

## if true, peer ip addresses are hidden
@export var streamer_mode : bool = false

## enable fancy, but distracting background color change following player turns
@export var background_color_follows_players : bool = true

## choose type of gui animation, non-distraction means that some in-game animation
## which look nice but can distract a player are disabled
## STUB
@export var gui_animation_mode := CFG.GuiAnimationMode.FULL

## Default first option when opening the game
@export var last_open_menu_tab := CFG.MainMenuTabs.LEARN

## Default first learn tab option when opening the game
@export var last_open_learn_tab := CFG.LearnTabs.TUTORIAL

## Default first option after opening the game should be last selected one
## [br]
## Changed to String for easier list update in GUI
@export var last_used_battle_preset_name : String

## Default first option after opening the game should be last selected one
@export var last_used_world_map : DataWorldMap


@export var fullscreen : bool:
	set(new):
		if new != fullscreen:
			(func(): UI.set_fullscreen(new)).call_deferred()
		fullscreen = new

## when player is in main menu his game window is kept minimized
## but turns fullscreen once the game starts
@export var keep_main_menu_windowed : bool = false

@export var login : String
## if true adds a random number suffix at the end of a login string
@export var randomise_join_login : bool = false

@export var last_hosting_address_used : String = "0.0.0.0"
@export var last_hosting_port_used : int = 12_000

@export var last_remote_host_address : String  = "127.0.0.1"
@export var last_remote_host_port : int = 12_000

