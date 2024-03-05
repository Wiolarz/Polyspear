extends Node

@export_category("Units")
@export var attacker_units : UnitSet
@export var defender_units : UnitSet


@export_category("Map")
@export var map_data : MapData

@export_category("AI")
@export var attacker_bot : StateMachine
@export var defender_bot : StateMachine


func _ready():
	B_GRID.GenerateGrid(map_data)

	BM.SetupUnits(self, attacker_units, defender_units)

	BM.AttackerBot = attacker_bot
	BM.DefenderBot = defender_bot


func restart_level():
	get_tree().reload_current_scene()
