extends Panel

@onready var _description : Label = $VBoxContainer/Columns/VBoxContainer/ReplayDescription
@onready var _play_button : Button = $VBoxContainer/Columns/VBoxContainer/PlayButton
@onready var _replays = $VBoxContainer/Columns/ScrollContainer/Replays
var _replay : BattleReplay

func _ready():

	Helpers.remove_all_children(_replays)
	var replay_paths = FileSystemHelpers.list_files_in_folder(CFG.REPLAY_DIRECTORY)
	replay_paths.reverse()
	for r in replay_paths:
		var b = Button.new()
		b.text = r
		b.name = r
		b.pressed.connect(func on_replay_clicked():
			_replay = load(CFG.REPLAY_DIRECTORY + r)
			_description.text = r \
				+ "\n map : "+ DataBattleMap.get_network_id(_replay.battle_map) \
				+ "\n moves : "+ str(_replay.moves.size())
			_play_button.disabled = false
		)
		_replays.add_child(b)


func _on_play_button_pressed():
	IM.perform_replay(_replay.resource_path)
