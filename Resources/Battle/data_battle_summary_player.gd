class_name DataBattleSummaryPlayer
extends Resource

## 2 line string - Player color | controller name [br]
## generated by Player.get_full_player_description
@export_multiline var player_description : String = "Unknown player\nNeutral"

## either "winner" or "loser"
@export var state : String = "winner"

## description of lost units
@export_multiline var losses : String = ""
