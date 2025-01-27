extends Node

enum PlaybackMode {
	NORMAL,
	FAST_FORWARD
}

# An ORDERED set of currently running tweens
var _running_tweens : Dictionary # Dictionary[Tween, (bool)] - just a set of tweens
var _main_tween : Tween
var _playback_mode : PlaybackMode = PlaybackMode.NORMAL


func create_my_tween() -> Tween:
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.stop()
	return tween


func main_tween() -> Tween:
	if not _main_tween or not _main_tween.is_valid():
		_main_tween = create_my_tween()
	return _main_tween


## Create a subtween, ran at the end of main tween (or a custom defined tween)
func subtween(parent: Tween = main_tween()) -> Tween:
	var tween = create_my_tween()
	tween.finished.connect(_tween_finished.bind(tween))
	
	_main_tween.tween_callback(_play_tween.bind(tween))

	return tween


## Change the speed of a main tween and all its subtweens
func change_speed(scale: float):
	for tween in _running_tweens:
		tween.set_speed_scale(scale)


## Instantly execute main tween and all its subtweens
func fast_forward():
	_playback_mode = PlaybackMode.FAST_FORWARD
	if _main_tween and _main_tween.is_valid():
		_main_tween.custom_step(INF)
	
	# Run all other tweens, in order they were created
	for tween in _running_tweens:
		tween.custom_step(INF)
	
	# From now on use a new main tween, since the old tween is invalid
	_main_tween = null
	_playback_mode = PlaybackMode.NORMAL


func _play_tween(tween: Tween):
	match _playback_mode:
		PlaybackMode.NORMAL:
			#tween.set_speed_scale(speed_scale)
			_running_tweens[tween] = true
			if tween.is_running():
				# Shouldn't ever happen
				assert(false, "Subtween is already running")
			tween.play()
		PlaybackMode.FAST_FORWARD:
			tween.play()
			tween.custom_step(INF)


func _tween_finished(tween: Tween):
	_running_tweens.erase(tween)

