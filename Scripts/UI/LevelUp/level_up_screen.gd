extends CanvasLayer


@onready var hide_button : Button = $ButtonHide

@onready var children = get_children()  # scene is static

var hidden : bool = true


func _on_button_hide_pressed():
	if hidden:
		for child in children:
			child.show()
		hidden = false
		return
	hidden = true
	for child in children:
		child.hide()
	
	hide_button.show()


func _on_button_confirm_pressed():
	hidden = true
	hide()
