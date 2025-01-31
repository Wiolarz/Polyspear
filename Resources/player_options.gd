class_name PlayerOptions
extends Resource

## once the game is launched it instantly start the game with default lobby values [br]
## depending on "use_default_battle" value starts either World/Battle
@export var autostart_map : bool

## Default starting screen when launching a game (autostart_map uses this variable)
@export var use_default_battle : bool
## if true all player slots are placed in control of AI controller [br]
## if false all slots are by default controlled by host (human player)
@export var use_default_AI_players : bool

## if true, peer ip addresses are hidden
@export var streamer_mode : bool

## enable fancy, but distracting background color change following player turns
@export var background_color_follows_players : bool

## Default first option after opening the game should be last selected one
## [br]
## Changed to String for easier list update in GUI
@export var last_used_battle_preset_name : String

## Default first option after opening the game should be last selected one
@export var last_used_world_preset : PresetWorld

@export var login : String
## if true adds a random number suffix at the end of a login string
@export var randomise_join_login : bool = false

@export var last_hosting_address_used : String = "0.0.0.0"
@export var last_hosting_port_used : int = 12_000

@export var last_remote_host_address : String  = "127.0.0.1"
@export var last_remote_host_port : int = 12_000

