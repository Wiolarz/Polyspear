extends Panel

func _ready():
	_on_tabs_tab_changed(CFG.LAST_OPENED_LEARN_TAB)


func _clear_tabs():
	for child in $MainContainer.get_children():
		child.hide()
	$MainContainer/TopMenu.show()



func _on_tutorial_button_pressed():
	_clear_tabs()
	$MainContainer/Tutorials.show()


func _on_puzzle_button_pressed():
	_clear_tabs()
	$MainContainer/Puzzles.show()


func _on_campaign_button_pressed():
	_clear_tabs()
	$MainContainer/CampaignBattles.show()


func _on_symbols_wiki_button_pressed():
	_clear_tabs()
	$MainContainer/WikiSymbols.show()


func _on_magic_wiki_button_pressed():
	_clear_tabs()
	$MainContainer/WikiMagic.show()


func _on_tabs_tab_changed(tab_index : int):
	assert(tab_index in CFG.LearnTabs.values(), "Disabled learn tab was selected")
	CFG.player_options.last_open_learn_tab = tab_index
	CFG.save_player_options()
	$MainContainer/TopMenu/TabBar.current_tab = tab_index
	match tab_index:
		0: pass  # disabled
		CFG.LearnTabs.TUTORIAL: _on_tutorial_button_pressed()
		CFG.LearnTabs.PUZZLE: _on_puzzle_button_pressed()
		CFG.LearnTabs.CAMPAIGN: _on_campaign_button_pressed()
		4: pass # disabled
		CFG.LearnTabs.SYMBOLS_WIKI: _on_symbols_wiki_button_pressed()
		CFG.LearnTabs.MAGIC_WIKI: _on_magic_wiki_button_pressed()
		7: pass  # stub
		_: push_error("_on_tabs_tab_changed index not supported: "+str(tab_index))
