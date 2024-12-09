extends Panel

@onready var _description : Label = $VBoxContainer/Columns/VBoxContainer/ReplayDescription
@onready var _play_button : Button = $VBoxContainer/Columns/VBoxContainer/PlayButton
@onready var _replay_buttons_container = $VBoxContainer/Columns/ScrollContainer/Replays
var _replay : BattleReplay


func _ready():
	refresh_replays_list()


func _on_visibility_changed():
	# sometimes called before ready inits @onready
	if _play_button:
		refresh_replays_list()


func refresh_replays_list():
	_play_button.disabled = true
	_replay = null
	Helpers.remove_all_children(_replay_buttons_container)
	var replay_paths = FileSystemHelpers.list_files_in_folder(CFG.REPLAY_DIRECTORY)
	replay_paths.reverse()
	for replay_path in replay_paths:
		var button = Button.new()
		button.text = replay_path
		button.name = replay_path
		button.pressed.connect(func on_replay_clicked():
			_replay = load(CFG.REPLAY_DIRECTORY + replay_path)
			_description.text = replay_path \
				+ "\n map : " + DataBattleMap.get_network_id(_replay.battle_map) \
				+ "\n moves : " + str(_replay.moves.size())
			var i = 0
			for army in _replay.units_at_start:
				var army_controller_name = _replay.get_player_name(i)
				var losses : PackedStringArray
				var is_winner = false
				
				if _replay.summary:
					is_winner = _replay.summary.players[i].state == "winner"
					losses = _replay.summary.players[i].losses.split("\n")
				
				_description.text += "\n%s%s army:" % [
					"👑 " if is_winner else "" , army_controller_name
				]
					
				for unit : DataUnit in army:
					var has_died = false
					var idx = losses.find(unit.unit_name)
					if idx != -1:
						losses.remove_at(idx)
						has_died = true
					
					_description.text += "\n  - %s%s" % [
						"☠️ " if has_died else "", unit.unit_name
					]
				
				i += 1

			_play_button.disabled = false
		)
		_replay_buttons_container.add_child(button)


func _on_play_button_pressed():
	IM.perform_replay(_replay.resource_path)
