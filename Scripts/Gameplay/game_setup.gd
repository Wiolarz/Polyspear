extends Node

@export_category("Units")
@export var AttackerUnits : UnitSet
@export var DefenderUnits : UnitSet


@export_category("Map")
@export var map_data : MapData

@export_category("AI")
@export var AttackerBot : StateMachine
@export var DefenderBot : StateMachine


func _ready():

	GRID.GenerateGrid(map_data)

	GM.SetupUnits(self, AttackerUnits, DefenderUnits)

	GM.AttackerBot = AttackerBot
	GM.DefenderBot = DefenderBot


func restart_level():
	get_tree().reload_current_scene()
