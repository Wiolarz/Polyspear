# `AnimationManager` for dummies

The `AnimationManager` (`ANIM` singleton) manages animation timings in gameplay. It relies on tweens and simplifies their management, providing custom speed/fast forward functions.

There are three main functions for tween creations:

`main_tween()` - returns a main, gameplay-related tween, where you append animations to play (by default) in sequence, should be used in a gameplay context.
`subtween()` - returns a new tween, which runs after main_tween finishes previous tweens and runs independently from it. Recommended for parallel animations
This call is functionally roughly equivalent to the following pseudocode:

```
var my_subtween = create_tween()
ANIM.main_tween().tween_callback(my_subtween.play)
```


`ui_tween()` - returns a new, generic UI tween, which you should manually play by calling either `ANIM.play_tween(tween, [settings])` if you want animation to be controlled by the `AnimationManager` or `tween.play()` if you don't.

NOTE: All tweens created by `ANIM` have overridden transitions to cubic and easing to ease-out.

For `ANIM.play_tween()` and `ANIM.subtween()` you can also pass an optional `ANIM.TweenPlaybackSettings` argument. At this moment you can pass an `ANIM.TweenPlaybackSettings.speed_independent()` if you want speed independent tween, which still reacts to fast-forward. More settings might be available in the future.

For examples of usage you can take a look at e.g. `unit_form.gd` (or just Ctrl+F).

For more details on dealing with tweens refer to Godot's `Tween` documentation (F1 or https://docs.godotengine.org/en/stable/classes/class_tween.html)

# How it actually functions in practice

When the move is processed in `BattleManager`'s `_perform_move_info()`, all previous animations are first fast forwarded, and then, inside `BattleGridState`'s logic, signals are sent to unit forms, which use `ANIM`'s tween creation functions. When the function finishes, the main tween is played.

A similar system will probably be in WorldManager