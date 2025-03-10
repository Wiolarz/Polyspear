class_name SymbolAnimation
extends SpriteFrames

## Holds all animations of a symbol along with offsets and certain frame-timings.
## Animation names matter and will dictate when given animation is played
## Convention:
## default - default active animation
## block - self-explanatory
## counter - self-explanatory

@export_category("Active Behavior")
@export var offset : Vector2 = Vector2(0,0)
@export var scale : Vector2 = Vector2(1,1)
##The frame of animation on witch the "hit" visually connects
@export var hit_on_frame : int = 0
@export_category("Teleporitng Projectile")
##Projectile animation, which will have its position set to the target hex
@export var projectile_animation_frames : SymbolAnimation
##For teleporting projectiles. The frame at witch the projectile animation should play
@export var teleport_at : int
@export_category("Blocking")
@export var blocking_offset : Vector2 = Vector2(0,0)
@export var blocking_scale : Vector2 = Vector2(1,1)
