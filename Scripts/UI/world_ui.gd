class_name WorldUI
extends CanvasLayer

@onready var good_label : Label = $HBoxContainer/GoodsLabel
@onready var city_ui : CityUi = $CityUi


func _process(_delta):
	if WM.current_player:
		good_label.text = WM.current_player.goods.to_string()


func refresh_player_buttons():
	var player_buttons = $Players.get_children()
	for i in range(player_buttons.size() - 1):
		var player := WM.players[i]
		var selected = player == WM.current_player
		var button = player_buttons[i+1] as Button
		var text = player.get_player_name()
		if selected:
			text = " > " + text
		button.text = text
		button.modulate = player.get_player_color()


func show_trade_ui(city : City, hero : ArmyForm):
	city_ui.show_trade_ui(city, hero)


func close_city_ui() -> void:
	pass


func _on_menu_pressed():
	IM.toggle_in_game_menu()


func _on_end_turn_pressed():
	WM.next_player_turn()
	refresh_player_buttons()

