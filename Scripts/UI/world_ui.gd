class_name WorldUI
extends CanvasLayer

@onready var good_label : Label = $HBoxContainer/GoodsLabel
@onready var city_ui : CityUi = $CityUi


func _process(_delta):
	good_label.text = WM.current_player.goods.to_string()


func refresh_player_buttons():
	var player_buttons = $Players.get_children()
	for i in range(player_buttons.size() - 1):
		var selected = WM.players[i] == WM.current_player
		var button = player_buttons[i+1] as Button
		button.text = WM.players[i].player_name
		button.modulate = Color.RED if selected else Color.WHITE


func show_trade_ui(city : City, hero : ArmyForm):
	city_ui.show_trade_ui(city, hero)


func close_city_ui() -> void:
	pass


func _on_menu_pressed():
	IM.show_in_game_menu()


func _on_end_turn_pressed():
	WM.next_player_turn()
	refresh_player_buttons()


func _on_line_edit_text_submitted(new_text : String):
	if new_text.strip_edges().to_lower() == "showmethemoney":
		WM.current_player.goods.add(Goods.new(100,100,100))
		print("moeny cheat")
	($ChatLineEdit as LineEdit).clear()
