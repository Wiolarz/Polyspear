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
var _log_file : FileAccess


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
			write_to_file(message)
		Severity.INFO:
			print(message)
			write_to_file(message)
		Severity.WARNING:
			print("WARN: ",message)
			push_warning(message)
			write_to_file(message)
		Severity.ERROR:
			print("ERROR: ", message)
			push_error(message)
			write_to_file(message)


func write_to_file(message : String):
	if not _log_file:
		_create_log_file()
	_log_file.store_line(message)
	_log_file.flush()


func _create_log_file():
	DirAccess.make_dir_recursive_absolute(CFG.LOGS_DIRECTORY)

	var ts = Time.get_datetime_string_from_system()
	var timestamp_for_filename = ts.replace(":", "_")
	var file_name = "%s.txt" % [timestamp_for_filename]

	var full_file_name = CFG.LOGS_DIRECTORY + file_name
	_log_file = FileAccess.open(full_file_name, FileAccess.WRITE)
	if not _log_file:
		push_error("log file creation failed %s" % [full_file_name] )


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
