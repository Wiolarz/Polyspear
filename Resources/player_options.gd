class_name PlayerOptions
extends Resource

@export var autostart_map : bool
@export var use_default_battle : bool
@export var use_default_AI_players : bool

@export var login : String
@export var randomise_join_login : bool = false

@export var last_hosting_address_used : String = "0.0.0.0"
@export var last_hosting_port_used : int = 12_000

@export var last_remote_host_address : String  = "127.0.0.1"
@export var last_remote_host_port : int = 12_000

