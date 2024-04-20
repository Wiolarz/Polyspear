# Singleton - UI
extends Node

func _ready():
	pass

func go_to_main_menu():
	$"/root/MainScene/MapEditor".hide_draw_menu()
	$"/root/MainScene/MainMenu".toggle_menu_visibility()

func show_in_game_menu():
	$"/root/MainScene/GameMenu/Menu"._toggle_menu_status()
