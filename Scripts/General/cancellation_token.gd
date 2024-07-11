class_name CancellationToken
extends Node

## Simple object that can be used to cancel long running opoerations with awaits etc.

var is_cancelled : bool

func cancel() -> void:
	is_cancelled = true

func is_canceled() -> bool:
	return is_cancelled
