class_name Helpers
extends RefCounted

func _init():
	assert(false, "static class, do not create")

static func remove_all_children(node: Node, include_internal : bool = false):
	var children = node.get_children(include_internal)
	for child in children:
		child.queue_free()
		node.remove_child(child)
