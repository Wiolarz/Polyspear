class_name PassiveButton
extends PanelContainer

signal button_pressed

## TODO add passive icon
## TODO add logic related on hover to display description

@onready var label = $Label
@onready var button = $Button

var pressed : bool :
	set(value):
		button.button_pressed = value
	get:
		return button.button_pressed


## Obtained used in world to distinquished passives already locked to a character
func load_passive(passive : HeroPassive, obtained : bool = false) -> void:
	if obtained:
		button.hide()
		label.show()
		label.text = passive.passive_name
	else:
		label.hide()
		button.show()
		button.text = passive.passive_name


func enable() -> void:
	button.disabled = false


func disable() -> void:
	button.disabled = true
	button.button_pressed = false


func selected() -> void:
	button.button_pressed = true

func deselect() -> void:
	button.button_pressed = false


## Only activated through human input
func _on_button_pressed():
	button_pressed.emit()
