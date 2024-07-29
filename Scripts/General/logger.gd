# singleton LOG
extends Node

enum Severity {
	DEBUG = 1, ## details usually not logged
	INFO,      ## general info, usually logged, skipped if running out of space
	WARNING,   ## concerning scenario, but not concerning enough to be ERROR
	ERROR,     ## this should not happen, something is wrong
}

const LOG_GENERIC := "generic"
const LOG_MENU := "menu"
const LOG_BATTLE := "battle"
const LOG_WORLD := "world"
const LOG_NETWORK := "net"

var _log_level_per_area := _init_log_levels()


func _init_log_levels() -> Dictionary:
	var result = {}
	result[LOG_GENERIC] = Severity.INFO
	result[LOG_MENU] = Severity.INFO
	result[LOG_BATTLE] = Severity.INFO
	result[LOG_WORLD] = Severity.INFO
	result[LOG_NETWORK] = Severity.INFO
	return result

func basic_log(\
		severity : Severity, \
		area : String, \
		message : String, \
		params : Variant = null \
		 ):
	if area not in _log_level_per_area:
		push_error("Log area not supported: \"%s\"" % [area])
		return
	if severity < _log_level_per_area[area]:
		return ##

	if params:
		message = message % params

	message = "[%s] %s" % [Time.get_time_string_from_system(), message]

	match severity:
		Severity.DEBUG:
			print(message)
		Severity.INFO:
			print(message)
		Severity.WARNING:
			print("WARN: ",message)
			push_warning(message)
		Severity.ERROR:
			print("ERROR: ", message)
			push_error(message)


func debug(area : String, message : String, params : Variant = null):
	basic_log(Severity.DEBUG, area, message, params)


func info(area : String, message : String, params : Variant = null):
	basic_log(Severity.INFO, area, message, params)


func warn(area : String, message : String, params : Variant = null):
	basic_log(Severity.WARNING, area, message, params)


func err(area : String, message : String, params : Variant = null):
	basic_log(Severity.ERROR, area, message, params)



class LoggerWithArea:
	var _area : String

	func _init(area : String):
		_area = area


	func debug(message : String, params : Variant = null):
		LOG.debug(_area, message, params)


	func info(message : String, params : Variant = null):
		LOG.info(_area, message, params)


	func warn(message : String, params : Variant = null):
		LOG.warn(_area, message, params)


	func err(message : String, params : Variant = null):
		LOG.err(_area, message, params)
