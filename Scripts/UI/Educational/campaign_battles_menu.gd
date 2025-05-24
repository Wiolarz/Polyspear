extends ContentBrowser



var _battle : ScriptedBattle :
	get:
		return _selected_item as ScriptedBattle


func _set_types():
	content_folder_path = CFG.CAMPAIGN_BATTLES_ELVES_PATH


func get_description() -> String:
	return _battle.scenario_name + "\n\n" + _battle.description


func activate_content() -> void:
	IM.start_scripted_battle(_battle)
