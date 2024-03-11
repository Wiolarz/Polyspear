extends Node

@export_category("Heroes")
@export var attacker_hero : Hero
@export var defender_hero : Hero


@export_category("Map")
@export var map_data : MapData

@export_category("AI")
@export var attacker_bot : StateMachine
@export var defender_bot : StateMachine


func _ready():
	B_GRID.GenerateGrid(map_data)

	BM.start_battle(self, [attacker_hero, defender_hero])

	BM.AttackerBot = attacker_bot
	BM.DefenderBot = defender_bot


func restart_level():
	get_tree().reload_current_scene()
