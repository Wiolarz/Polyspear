extends Control


class DisappearingEntry:
	var content : String
	var time_left : float


## Messages and similar which are showed some time even when the chat is not
## activated.
var entries : Array[DisappearingEntry]

## this variable is needed to successfully remove focus from text field when
## content is submitted
var just_submitted : bool = false

@onready var full_log = $VBoxContainer/HBoxContainer/FullLog
@onready var full_log_content = $VBoxContainer/HBoxContainer/FullLog/FullLogContent
@onready var short_log = $VBoxContainer/HBoxContainer/ShortInactiveLog
@onready var text_input = $VBoxContainer/ChatLineEdit
@onready var scroll_bar = full_log.get_v_scroll_bar()


func _ready():
	NET.chat_message_arrived.connect(_on_message_arrived)
	NET.chat_log_cleared.connect(clear_short_log)


func _exit_tree():
	NET.chat_message_arrived.disconnect(_on_message_arrived)
	NET.chat_log_cleared.disconnect(clear_short_log)


func _process(delta : float):
	# TODO move these inputs to some invisible button probably
	if not just_submitted and Input.is_action_just_pressed("KEY_ACTIVATE_CHAT"):
		activate()
	just_submitted = false
	roll_entries(delta)


func roll_entries(delta : float):
	var threshold : int = -1
	for i in range(entries.size()):
		var entry = entries[i]
		entry.time_left -= delta
		if entry.time_left < 0.0:
			threshold = i
	if threshold >= 0:
		entries = entries.slice(threshold + 1)
		refresh_short_log()


func refresh_short_log():
	if is_active():
		return
	const max_messages = 9
	for child in short_log.get_children():
		short_log.remove_child(child)
		child.queue_free()
	var index : int = max(0, entries.size() - max_messages)
	while index < entries.size():
		var message = Label.new()
		message.text = entries[index].content
		short_log.add_child(message)
		index = index + 1


func refresh_full_log():
	var should_scroll_down = scroll_bar.ratio >= 1
	full_log_content.text = NET.chat_log # maybe better way than direct read?
	if should_scroll_down:
		scroll_bar.ratio = 1


func is_active():
	return full_log.visible


func activate():
	text_input.editable = true
	text_input.grab_focus()
	short_log.hide()
	full_log.show()
	refresh_full_log()
	scroll_chat_down()


func deactivate():
	text_input.editable = false
	# this is needed to completely loose focus
	text_input.hide()
	text_input.show()
	short_log.show()
	full_log.hide()
	refresh_short_log()


func clear_short_log():
	entries = []


func scroll_chat_down():
	scroll_bar.ratio = 1


func send_chat_message(content : String):
	if (content.length() == 0):
		return
	NET.send_chat_message(content)
	scroll_chat_down()
	just_submitted = true


func _on_message_arrived(content : String):
	var entry = DisappearingEntry.new()
	entry.content = content
	entry.time_left = 15.0
	entries.append(entry)
	if is_active():
		refresh_full_log()
	else:
		refresh_short_log()


func _on_chat_line_edit_text_submitted(new_text):
	# TODO: Move it somewhere else
	var array_get = func (array: PackedStringArray, index: int) \
		-> String:
		if array.size() <= index: return ""
		else: return array[index]
	
	if new_text.length() >= 1 and new_text[0] == '/':
		var args = new_text.split(" ", false)
		var cheat = args[0].substr(1).strip_edges().to_lower()
		match cheat:
			"money":
				WM.cheat_money(
					int(array_get.call(args, 1)),
					int(array_get.call(args, 2)),
					int(array_get.call(args, 3))
				)
				print("money cheat")
			"fast":
				WM.hero_speed_cheat(int(array_get.call(args, 1)))
				print("travel cheat")
			"levelup":
				WM.hero_level_up(int(array_get.call(args, 1)))
				print("levelup cheat")
			_:
				print("unknown cheat")
	else:
		send_chat_message(new_text)

	(text_input as LineEdit).clear()
	deactivate()


func _on_chat_line_edit_focus_entered():
	if not is_active():
		activate()
