class_name DataBattleSummaryPlayer
extends Resource

@export_multiline var player_description : String = "Unknown player\nNeutral"

## probably one of "winner", "loser", "survivor", "deserter"
@export var state : String = "survivor"

## description of units lost
@export_multiline var losses : String = ""
