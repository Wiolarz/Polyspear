extends Node2D

@export var clothes : clothes

var speed = 40

func _ready():
	$Sprite2D.texture = clothes.sprite

