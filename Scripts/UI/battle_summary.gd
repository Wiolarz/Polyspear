class_name BattleSummary
extends Control

signal continued

const BATTLE_SUMMARY_SCENE_PATH := "res://Scenes/UI/Battle/BattleSummary.tscn"
const BATTLE_SUMMARY_PLAYER_SCENE_PATH = "res://Scenes/UI/Battle/BattleSummaryPlayerStats.tscn"

@onready var color_rect = $ColorRect
@onready var title_label = $VBoxContainer/Title
@onready var player_list = $VBoxContainer/Players


static func create(parent:Node, info: DataBattleSummary, \
			continue_callback : Callable) -> BattleSummary:
	var result = load(BATTLE_SUMMARY_SCENE_PATH).instantiate()
	parent.add_child(result)
	result.set_visible_state_from_info(info)
	if continue_callback:
		result.continued.connect(continue_callback)
	return result


static func adjust_color(color : Color):
	return Color(color[0] * 0.75, color[1] * 0.75, color[2] * 0.75, color[3])


func set_visible_title(title : String):
	title_label.text = title


func set_visible_color(color : Color):
	color_rect.color = BattleSummary.adjust_color(color)


func set_visible_state_from_info(content : DataBattleSummary):
	if content == null:
		content = BM.DataBattleSummary.new()

	set_visible_title(content.title)
	set_visible_color(content.color)

	clear_players()
	for player in content.players:
		var player_stats : BattleSummaryPlayerStats = \
			load(BATTLE_SUMMARY_PLAYER_SCENE_PATH).instantiate()
		player_list.add_child(player_stats)
		player_stats.player_description.text = player.player_description
		player_stats.state_label.text = player.state
		player_stats.losses_list.text = player.losses


func clear_players():
	for child in player_list.get_children():
		player_list.remove_child(child)
		child.queue_free()


func _on_button_continue_pressed():
	continued.emit()
	for connection in continued.get_connections():
		continued.disconnect(connection.callable)

