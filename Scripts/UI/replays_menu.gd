extends Panel

@onready var _column_container = $MarginContainer/VBoxContainer/Columns

@onready var _list : Control = _column_container.get_node("ScrollContainer")
@onready var _content : Control = _column_container.get_node("VBoxContainer")

@onready var _description : Label = _content.get_node("ReplayDescription")
@onready var _play_button : Button = _content.get_node("PlayButton")
@onready var _replay_buttons_container = _list.get_node("Replays")

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
		button.text_overrun_behavior = TextServer.OverrunBehavior.OVERRUN_TRIM_ELLIPSIS
		button.clip_text = true
		button.custom_minimum_size = Vector2(0, 64)
		button.pressed.connect(_on_replay_clicked.bind(replay_path))
		_replay_buttons_container.add_child(button)


func _on_replay_clicked(replay_path: String):
	_replay = load(CFG.REPLAY_DIRECTORY + replay_path)
	_description.text = replay_path \
		+ "\n map : " + DataBattleMap.get_network_id(_replay.battle_map) \
		+ "\n moves : " + str(_replay.moves.size())
	var i = -1
	for army in _replay.units_at_start:
		i += 1
		var army_controller_name = _replay.get_player_name(i)
		var losses : PackedStringArray
		var is_winner = false
		var timer = _replay.player_initial_timers_ms[i] \
				if _replay.player_initial_timers_ms.size() > i else 0
		var increment = _replay.player_increments_ms[i] \
				if _replay.player_increments_ms.size() > i else 0
		
		if _replay.summary:
			is_winner = _replay.summary.players[i].state == "winner"
			losses = _replay.summary.players[i].losses.split("\n")
		
		_description.text += "\n%s%s army:  [%02d:%02d +%ds/turn]" % [
			"👑 " if is_winner else "" , army_controller_name,
			(timer/1000) / 60, (timer/1000) % 60, increment / 1000
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

	_play_button.disabled = false


func _on_play_button_pressed():
	IM.perform_replay(_replay.resource_path)
