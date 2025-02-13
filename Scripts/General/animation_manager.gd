# Singleton - ANIM
extends Node

enum PlaybackMode {
	NORMAL,
	FAST_FORWARD
}

# An ORDERED set of currently running tweens with their settings
var _running_tweens : Dictionary # Dictionary[Tween, TweenPlaybackSettings]
var _main_tween : Tween
var _playback_mode : PlaybackMode = PlaybackMode.NORMAL
var _speed_scale : float = 1.0


func _process(_delta: float):
	# Set tweens' speed based on game speed (normal = 1.0, instant >> 1.0)
	_speed_scale =  CFG.animation_speed_frames / CFG.AnimationSpeed.NORMAL
	change_speed(_speed_scale)


func create_my_tween(settings := TweenPlaybackSettings.new()) -> Tween:
	var tween = get_tree().create_tween()
	tween.set_ease(CFG.anim_default_ease).set_trans(CFG.anim_default_trans)
	if settings.influenced_by_game_speed:
		tween.set_speed_scale(_speed_scale)
	tween.stop()
	return tween


## Get a main gameplay tween for in-game animations to append to
func main_tween() -> Tween:
	if not _main_tween or not _main_tween.is_valid():
		_main_tween = create_my_tween()
	return _main_tween


## Create a subtween, ran when the specified tween 
## (by default main tween) finishes all previous animations
func subtween(parent : Tween = main_tween(), settings := TweenPlaybackSettings.new()) -> Tween:
	var tween = create_my_tween(settings)
	tween.finished.connect(_tween_finished.bind(tween))
	parent.tween_callback(play_tween.bind(tween, settings))

	return tween


## Create a tween independent of main tween
func ui_tween():
	# TODO tweaks for ui tweens, if you wish
	var tween = create_my_tween()
	return tween


## Change the speed of a main tween and all its subtweens
func change_speed(scale : float):
	if _main_tween: # TODO is this check useful?
		_main_tween.set_speed_scale(scale)
	for tween in _running_tweens:
		if _running_tweens[tween].influenced_by_game_speed:
			tween.set_speed_scale(scale)


## Instantly execute main tween and all its subtweens
func fast_forward() -> void:
	_playback_mode = PlaybackMode.FAST_FORWARD
	if _main_tween and _main_tween.is_valid():
		_main_tween.custom_step(INF)
	
	# Run all other tweens, in order they were created
	for tween in _running_tweens:
		tween.custom_step(INF)
	
	# From now on use a new main tween, since the old tween is invalid
	_main_tween = null
	_playback_mode = PlaybackMode.NORMAL


## is main tween playing
func is_playing() -> bool:
	return _main_tween != null and _main_tween.is_running()


## Play the specified tween and let it be managed by the animation manager
func play_tween(tween : Tween, settings := TweenPlaybackSettings.new()) -> void:
	match _playback_mode:
		PlaybackMode.NORMAL:
			tween.set_speed_scale(_speed_scale)
			_running_tweens[tween] = settings
			
			# Shouldn't ever happen
			assert(not tween.is_running(), "Subtween is already running")
			tween.play()
		PlaybackMode.FAST_FORWARD:
			tween.play()
			tween.custom_step(INF)


func _tween_finished(tween: Tween) -> void:
	_running_tweens.erase(tween)


class TweenPlaybackSettings:
	var influenced_by_game_speed := true

	static func speed_independent() -> TweenPlaybackSettings:
		var settings = TweenPlaybackSettings.new()
		settings.influenced_by_game_speed = false
		return settings
