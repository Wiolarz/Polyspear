extends Line2D

var start_width : float
var start_scale : Vector2


func _ready() -> void:
	start_scale = scale
	start_width = width


func _process(_delta : float) -> void:
	var sinus = sin(PI * 0.0004 * Time.get_ticks_msec())
	width = start_width * (1.0 + 0.15 * sinus)
	scale = start_scale * (1.0 + 0.0 * sinus)
