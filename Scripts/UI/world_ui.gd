class_name WorldUI
extends CanvasLayer

@onready var good_label : Label = $HBoxContainer/GoodsLabel
@onready var city_ui : CityUi = $CityUi
@onready var heroes_list : BoxContainer = $HeroesList



func _ready():
	city_ui.purchased_hero.connect(refresh_heroes)


func _process(_delta):
	if WM.world_game_is_active():
		good_label.text = WS.get_current_player().goods.to_string()


func game_started():
	refresh_player_buttons()


func refresh_heroes():
	Helpers.remove_all_children(heroes_list)
	var player_index = WS.current_player_index
	var player_state = WS.get_faction_by_index(player_index)
	if not player_state:
		return
	for army in player_state.hero_armies:
		var button := TextureButton.new()
		var hero_texture = army.hero.template.data_unit.texture_path
		button.texture_normal = load(hero_texture)
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.custom_minimum_size = Vector2(200,200)
		if army.hero.movement_points == 0:
			button.modulate = Color.DIM_GRAY
		if WM.selected_hero and WM.selected_hero.entity == army:
			button.modulate = Color.FIREBRICK
		button.pressed.connect(func ():
			if army.controller_index == WM.get_current_player().index:
				WM.set_selected_hero(army)
				UI.camera.center_camera(WM.get_army_form(army))
		)
		heroes_list.add_child(button)


func refresh_player_buttons():
	var player_buttons = $Players.get_children()
	for i in range(player_buttons.size() - 1):
		var player := IM.players[i]
		var selected = player == WM.get_current_player()
		var button = player_buttons[i+1] as Button
		var text = player.get_player_name()
		if selected:
			text = " > " + text
		button.text = text
		button.modulate = player.get_player_color().color


func show_trade_ui(city : City):
	city_ui.show_trade_ui(city)


func _on_menu_pressed():
	UI.main_menu.open_in_game_menu()


func _on_end_turn_pressed():
	WM.end_turn()
