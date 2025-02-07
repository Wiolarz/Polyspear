extends Control

@export var callback : Callable
@export var title : String

@onready var _actual_slider : Slider = $Slider
@onready var _mute_button : Button = $ButtonMute
@onready var _title_label : Label = $Label

func _ready() -> void:
	_title_label.text = title
