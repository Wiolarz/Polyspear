extends Area2D

signal got_hit(value)

func damage(value):
	got_hit.emit(value)
