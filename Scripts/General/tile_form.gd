class_name TileForm

extends Area2D

var coord : Vector2i

var type : String = "sentinel"

var place : Place

var grid_type : GameSetupInfo.GameMode = GameSetupInfo.GameMode.WORLD


static func create_world_tile(data: DataTile, new_coord : Vector2i, \
		new_place : Place) -> TileForm:
	var result = CFG.HEX_TILE_FORM_SCENE.instantiate()
	result._set_coord(new_coord)
	result._set_texture(load(data.texture_path))
	result.type = data.type
	result.place = new_place
	return result


static func create_battle_tile(data: DataTile, new_coord : Vector2i) -> TileForm:
	var result = CFG.HEX_TILE_FORM_SCENE.instantiate()
	result.grid_type = GameSetupInfo.GameMode.BATTLE
	result.type = data.type
	result._set_coord(new_coord)
	result._set_texture(load(data.texture_path))
	return result


func _on_input_event(_viewport : Node, event : InputEvent, _shape_idx : int):
	# normal gameplay - on click
	if event.is_action_pressed("KEY_SELECT"):
		UI.grid_input_listener(coord, grid_type, false)

	# for map editor - on mouse move while button pressed
	if Input.is_action_pressed("KEY_SELECT"):
		UI.grid_input_listener(coord, grid_type, true)


func _process(_delta):
	$PlaceLabel.text = ""
	if place != null: #TEMP
		$PlaceLabel.text = place.get_map_description()


## for map editor only
func paint(brush : DataTile) -> void:
	type = brush.type
	$Sprite2D.texture = load(brush.texture_path)


func _set_coord(new_coord: Vector2i):
	coord = new_coord
	$CoordLabel.text = str(new_coord)


func _set_texture(texture: Texture2D):
	$Sprite2D.texture = texture


