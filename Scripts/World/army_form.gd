class_name ArmyForm
extends Node2D

var entity: Army

var coord:
	get: return entity.coord


var controller:
	get: return entity.controller

func _process(_delta):
	var hero = entity.hero
	if hero:
		$MoveLabel.text = "Move %d / %d" % [hero.movement_points, hero.max_movement_points]


static func create_hero_army(player : Player, hero_data : DataHero) -> ArmyForm:
	var result = CFG.DEFAULT_ARMY_FORM.instantiate()
	result.entity = Army.new()
	result.entity.hero = Hero.new()

	result.name = hero_data.hero_name
	result.entity.controller = player
	result.entity.hero = Hero.create_hero(hero_data)
	result.entity.hero.controller = player
	result.get_node("sprite_unit").texture = \
		load(hero_data.data_unit.texture_path)
	return result


func move(tile):
	position = tile.position
	entity.coord = tile.coord


func on_end_of_turn(player : Player):
	if player == entity.controller and entity.hero:
		entity.hero.movement_points = entity.hero.max_movement_points


func set_selected(is_selected : bool) -> void:
	$sprite_color.modulate = Color.RED if is_selected else Color.WHITE
