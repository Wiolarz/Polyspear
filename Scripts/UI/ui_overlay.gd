extends CanvasLayer

@onready var battle_container : Container = $BattleContainer
@onready var world_container : Container = $WorldContainer


func show_battle_summary(info : DataBattleSummary, finalize_callback):
	for child in battle_container.get_children():
		battle_container.remove_child(child)
		child.queue_free()

	var true_callback = func () -> void:
		if finalize_callback is Callable:
			finalize_callback.call()
		battle_container.hide()

	BattleSummary.create(battle_container, info, true_callback)
	show() #TODO fix it so it can be removed
	battle_container.show()


func show_world_summary(info : DataWorldSummary, finalize_callback):
	for child in world_container.get_children():
		world_container.remove_child(child)
		child.queue_free()

	var true_callback = func () -> void:
		if finalize_callback is Callable:
			finalize_callback.call()
		world_container.hide()

	WorldSummary.create(world_container, info, true_callback)
	show() #TODO fix it so it can be removed
	world_container.show()


