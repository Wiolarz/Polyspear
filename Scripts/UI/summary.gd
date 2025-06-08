class_name Summary
extends Control

signal continued


@onready var color_rect = $ColorRect
@onready var title_label = $VBoxContainer/Title
@onready var player_list = $VBoxContainer/Players



static func adjust_color(color : Color) -> Color:
	return Color(color[0] * 0.75, color[1] * 0.75, color[2] * 0.75, color[3])


func set_visible_title(title : String) -> void:
	title_label.text = title


func set_visible_color(color : Color) -> void:
	color_rect.color = Summary.adjust_color(color)


func clear_players():
	for child in player_list.get_children():
		player_list.remove_child(child)
		child.queue_free()


func _on_button_continue_pressed():
	continued.emit()
	for connection in continued.get_connections():
		continued.disconnect(connection.callable)
