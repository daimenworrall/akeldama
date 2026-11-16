extends CanvasLayer
## Modal lifecycle, pause ownership and input; the panel owns presentation.
signal open_changed(open: bool)
const JournalPanel = preload("res://features/quests/ui/quest_journal_panel.gd")
const Dependencies = preload("res://features/quests/quest_dependencies.gd")
var panel := JournalPanel.new()
var overlay := Control.new()
var is_open := false
var _was_paused := false
var reset_dialog := ConfirmationDialog.new()
var _reset_id := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 8
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.02, 0.04, 0.8)
	overlay.add_child(dim)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.anchor_left = 0.08
	panel.anchor_right = 0.92
	panel.anchor_top = 0.1
	panel.anchor_bottom = 0.9
	overlay.add_child(panel)
	panel.close_requested.connect(close)
	panel.reset_requested.connect(_request_reset)
	reset_dialog.title = "Reset quest progress"
	reset_dialog.ok_button_text = "Reset quests"
	reset_dialog.confirmed.connect(_confirm_reset)
	reset_dialog.canceled.connect(func() -> void:
		_reset_id = ""
		panel.focus_default.call_deferred())
	add_child(reset_dialog)
	overlay.hide()

func setup(journal: RefCounted, terrain: Resource) -> void:
	panel.journal = journal
	panel.terrain = terrain
	panel.track_requested.connect(journal.track)
	journal.changed.connect(func() -> void:
		if is_open:
			panel.refresh())

func open() -> void:
	if is_open:
		return
	_was_paused = get_tree().paused
	is_open = true
	get_tree().paused = true
	panel.refresh()
	overlay.show()
	panel.focus_default()
	open_changed.emit(true)

func close() -> void:
	if not is_open:
		return
	is_open = false
	reset_dialog.hide()
	_reset_id = ""
	overlay.hide()
	get_tree().paused = _was_paused
	open_changed.emit(false)

func _input(event: InputEvent) -> void:
	if is_open and reset_dialog.visible:
		if event.is_action_pressed("ui_cancel") and not event.is_echo():
			reset_dialog.hide()
			get_viewport().set_input_as_handled()
		return
	if is_open and not event.is_echo() and (event.is_action_pressed("quest_journal") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_game")):
		close()
		get_viewport().set_input_as_handled()

func _request_reset(id: String) -> void:
	var affected := Dependencies.affected_by_reset(panel.journal.catalog, id)
	if affected.is_empty():
		return
	_reset_id = id
	var names := PackedStringArray()
	for quest_id in affected:
		names.append("• " + panel.journal.catalog.quest(quest_id).title)
	reset_dialog.dialog_text = "Clear progress and completion for this quest and every dependent quest?\n\n" + "\n".join(names)
	reset_dialog.popup_centered()

func _confirm_reset() -> void:
	panel.journal.reset(_reset_id)
	_reset_id = ""
	panel.focus_default.call_deferred()

func _exit_tree() -> void:
	if is_open:
		get_tree().paused = _was_paused
