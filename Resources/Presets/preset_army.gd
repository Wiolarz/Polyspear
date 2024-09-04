class_name PresetArmy
extends Resource


@export var units : Array[DataUnit]

@export var hero : PackedScene = null # TODO create a presethero resource

## starting team assigned - 0 - no team(FFA)
@export var team : int = 0
