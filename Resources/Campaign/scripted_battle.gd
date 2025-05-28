class_name ScriptedBattle
extends Resource

@export var scenario_name : String

## used for "Practice mode" content menu description [br]
## for campaign battles its a spot for developers notes
@export_multiline var description : String


## index of the army player will control
@export var player_side : int = 0


@export var armies : Array[PresetArmy] = []

@export var battle_map : DataBattleMap

@export var text_bubbles : Array[TextBubble] = []


# TODO add function that takes in player world army to use it during scripted battle

## returns true if a input should be locked until text bubbles are resolved
func show_text_bubbles(battle_state : BattleGridState) -> void:
	for text_bubble in text_bubbles:
		if text_bubble.is_prerequisite_fullfilled(battle_state):
			print(text_bubble.text)
			BM._battle_ui.show_text_bubble(text_bubble)
