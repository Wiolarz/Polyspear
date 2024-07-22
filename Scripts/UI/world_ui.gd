class_name WorldUI
extends CanvasLayer

@onready var good_label : Label = $HBoxContainer/GoodsLabel
@onready var city_ui : CityUi = $CityUi
@onready var heroes_list : BoxContainer = $HeroesList


func _ready():
	city_ui.purchased_hero.connect(refresh_heroes)


func _process(_delta):
	if WM.current_player:
		good_label.text = WM.current_player.goods.to_string()


func game_started():
	refresh_player_buttons()
	$YouWinPanel.hide()


func refresh_heroes(player : Player = WM.current_player):
	Helpers.remove_all_children(heroes_list)
	for hf in player.hero_armies:
		var button := TextureButton.new()
		var hero_texture = hf.entity.hero.template.data_unit.texture_path
		button.texture_normal = load(hero_texture)
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.custom_minimum_size = Vector2(200,200)
		if hf.entity.hero.movement_points == 0:
			button.modulate = Color.DIM_GRAY
		if WM.selected_hero == hf:
			button.modulate = Color.FIREBRICK
		button.pressed.connect(func ():
			if hf.controller == WM.current_player:
				WM.set_selected_hero(hf)
				UI.camera.center_camera(hf)
		)
		heroes_list.add_child(button)


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
		button.modulate = player.get_player_color().color


func show_trade_ui(city : City, hero : ArmyForm):
	city_ui.show_trade_ui(city, hero)


func close_city_ui() -> void:
	pass


func show_you_win(player : Player):
	var style_box = ($YouWinPanel as Panel).get_theme_stylebox("panel")
	if not style_box is StyleBoxFlat:
		return
	var style_box_flat = style_box as StyleBoxFlat
	style_box_flat.bg_color = player.get_player_color().color
	$YouWinPanel.show()


func _on_menu_pressed():
	IM.toggle_in_game_menu()


func _on_end_turn_pressed():
	WM.next_player_turn()
	refresh_player_buttons()
	refresh_heroes(WM.current_player)
