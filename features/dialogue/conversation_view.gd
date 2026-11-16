extends CanvasLayer
## Renders session state and raises player intentions through buttons.
signal choice_selected(index: int)
signal dismiss_requested
var panel := PanelContainer.new()
var speaker := Label.new()
var line := Label.new()
var options := VBoxContainer.new()
var hint := Label.new()

func _ready() -> void:
	layer = 5
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hint.position = Vector2(20, -40)
	root.add_child(hint)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 32
	panel.offset_right = -32
	panel.offset_top = -250
	panel.offset_bottom = -24
	root.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	margin.add_child(content)
	content.add_child(speaker)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(line)
	content.add_child(options)
	panel.hide()

func present(session: RefCounted) -> void:
	panel.show()
	speaker.text = session.current.speaker
	line.text = session.current.text
	for child in options.get_children():
		options.remove_child(child)
		child.queue_free()
	var choices: Array = session.choices()
	if choices.is_empty():
		_button("Close", func() -> void: dismiss_requested.emit())
	for index in range(choices.size()):
		_button(choices[index].text, func() -> void: choice_selected.emit(index))
	options.get_child(0).grab_focus()
	hint.hide()

func _button(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(callback)
	options.add_child(button)

func close() -> void:
	panel.hide()
	hint.show()
