## This is a GDscript Node wich gets automatically added as Autoload while installing the addon.
##
## It can run in the background to comunicate with Discord.
## You don't need to use it. If you remove it make sure to run [code]DiscordRPC.run_callbacks()[/code] in a [code]_process[/code] function.
##
## @tutorial: https://github.com/vaporvee/discord-rpc-godot/wiki
extends Node


func _ready() -> void:
	init_discord_rich_presence()


func _process(_delta) -> void:
	DiscordRPC.run_callbacks()


func init_discord_rich_presence():
	DiscordRPC.app_id = 1406284593891643483  # Application ID
	DiscordRPC.state = "Looking for a Quest"
	DiscordRPC.large_image = "outpost_wood"

	DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system())

	DiscordRPC.refresh()  # Always refresh after changing the values!
