extends Label

@export var gun : Gun



func _process(delta):
	text = str(gun.ammuniton if gun else "no gun")
