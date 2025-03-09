class_name SymbolAnimation
extends SpriteFrames

@export_category("General")
@export var offset : Vector2 = Vector2(0,0)
@export var scale : Vector2 = Vector2(1,1)
##The frame of animation on witch the "hit" visually connects
@export var hit_on_frame : int = 0
@export_category("Teleporitng Projectile")
##For teleporting projectiles. The frame at witch the animation should teleport
@export var teleport_at : int
##Offset after teleporting
@export var teleport_offset : Vector2
