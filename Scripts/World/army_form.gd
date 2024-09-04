class_name ArmyForm
extends Node2D

var entity : Army

var coord:
	get: return entity.coord


var controller:
	get: return entity.controller

func _init():
	name = "ArmyForm"

func _process(_delta):
	var hero = entity.hero
	if hero:
		$MoveLabel.text = "Move %d / %d" % [hero.movement_points, hero.max_movement_points]
		$DescriptionLabel.text =  "%s\nlv %d (%d)" % [hero.hero_name, hero.level, hero.xp]
		$sprite_unit.modulate = Color.DIM_GRAY if not has_movement_points() \
				else Color.WHITE


static func get_placeholder_image() -> Resource:
	return load("res://Art/units/neutral/wood_dryad.png")


static func create_form_of_army(hex : WorldHex, _coord : Vector2i, \
		position_ : Vector2) -> ArmyForm:
	if not hex or not hex.army:
		return null
	var result : ArmyForm = CFG.DEFAULT_ARMY_FORM.instantiate()
	var army : Army = hex.army
	result.entity = army
	var image = ArmyForm.get_placeholder_image()
	if army.hero:
		result.name = army.hero.hero_name
		image = load(army.hero.data_unit.texture_path)
	else:
		result.name = "Neutral army TODO some name"
		image = load(army.units_data[0].texture_path)
		result.get_node("sprite_unit").scale = Vector2(0.9, 0.9)
		result.get_node("MoveLabel").text = ""
		result.get_node("DescriptionLabel").text = ""
	result.get_node("sprite_unit").texture = image
	result.position = position_
	return result


func has_movement_points() -> bool:
	return entity.hero.movement_points > 0


func place_on(tile):
	position = tile.position


func spend_movement_point() -> void:
	assert(entity.hero.movement_points > 0)
	entity.hero.movement_points -= 1


func set_selected(is_selected : bool) -> void:
	$sprite_color.modulate = Color.RED if is_selected else Color.WHITE


func apply_losses(losses : Array[DataUnit]):
	entity.apply_losses(losses)
