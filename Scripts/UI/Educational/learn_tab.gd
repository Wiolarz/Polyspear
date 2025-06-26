extends Panel

func _ready():
	_on_tabs_tab_changed(CFG.LAST_SELECTED_LEARN_TAB)


func _clear_tabs():
	$VBox/Tutorials.hide()
	$VBox/Puzzles.hide()
	$VBox/CampaignBattles.hide()
	$VBox/WikiSymbols.hide()
	$VBox/WikiMagic.hide()


func _on_tutorial_button_pressed():
	_clear_tabs()
	$VBox/Tutorials.show()


func _on_puzzle_button_pressed():
	_clear_tabs()
	$VBox/Puzzles.show()


func _on_campaign_button_pressed():
	_clear_tabs()
	$VBox/CampaignBattles.show()


func _on_symbols_wiki_button_pressed():
	_clear_tabs()
	$VBox/WikiSymbols.show()


func _on_magic_wiki_button_pressed():
	_clear_tabs()
	$VBox/WikiMagic.show()


func _on_tabs_tab_changed(tab_index : int):
	CFG.player_options.last_selected_learn_Tab = tab_index
	CFG.save_player_options()

	match tab_index:
		0: pass  # disabled
		1: _on_tutorial_button_pressed()
		2: _on_puzzle_button_pressed()
		3: _on_campaign_button_pressed()
		4: pass # disabled
		5: _on_symbols_wiki_button_pressed()
		6: _on_magic_wiki_button_pressed()
		7: pass  # stub
		_: push_error("_on_tabs_tab_changed index not supported: "+str(tab_index))
