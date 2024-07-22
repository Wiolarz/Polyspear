extends CanvasLayer

@onready var container : Container = $Container


func show_summary(info : DataBattleSummary, finalize_callback):
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

	var true_callback = func () -> void:
		if finalize_callback is Callable:
			finalize_callback.call()
		hide_summary()

	BattleSummary.create(container, info, true_callback)

	show()
	container.show()


func hide_summary():
	hide()
	container.hide()
