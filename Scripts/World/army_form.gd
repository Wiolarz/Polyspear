class_name ArmyForm
extends Node2D

var entity: Army

var coord:
	get: return entity.coord


var controller:
	get: return entity.controller

func _ready():
	entity = Army.new()
	entity.hero = Hero.new()
	entity.hero.controller = entity.controller

func _process(_delta):
	var hero = entity.hero
	if hero:
		$MoveLabel.text = "Move %d / %d" % [hero.movement_points, hero.max_movement_points]


func move(tile):
	position = tile.position
	entity.coord = tile.coord


func set_selected(is_selected : bool) -> void:
	$sprite_color.modulate = Color.RED if is_selected else Color.WHITE
