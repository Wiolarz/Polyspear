extends Node


@export var AttackerUnits : UnitSet
@export var DefenderUnits : UnitSet

@export var map_data : MapData


func _ready():

    GRID.GenerateGrid(map_data)

    GM.SetupUnits(AttackerUnits, DefenderUnits)



