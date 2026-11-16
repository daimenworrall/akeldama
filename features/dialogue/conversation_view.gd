extends CanvasLayer
## Renders session state and raises player intentions through buttons.
signal choice_selected(index: int)
signal dismiss_requested
var panel := PanelContainer.new()
var speaker := Label.new()
var line := Label.new()
var options := VBoxContainer.new()
var hint := Label.new()
var root := Control.new()
var line_scroll := ScrollContainer.new()
var choice_scroll := ScrollContainer.new()
var choice_hint := Label.new()

func _ready() -> void:
	layer = 5
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.resized.connect(_layout)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hint.position = Vector2(20, -40)
	root.add_child(hint)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 32
	panel.offset_right = -32
	panel.offset_top = -330
	panel.offset_bottom = -24
	root.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	margin.add_child(content)
	content.add_child(speaker)
	speaker.clip_text = true
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	line_scroll.custom_minimum_size.y = 64
	line_scroll.add_child(line)
	content.add_child(line_scroll)
	choice_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	choice_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	choice_scroll.custom_minimum_size.y = 48
	choice_scroll.follow_focus = true
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_scroll.add_child(options)
	content.add_child(choice_scroll)
	choice_hint.text = "↑/↓ or D-pad to choose · Enter/A to select · Scroll for more"
	choice_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(choice_hint)
	_layout()
	panel.hide()

func present(session: RefCounted) -> void:
	panel.show()
	speaker.text = session.current.speaker
	line.text = session.current.text
	line_scroll.scroll_vertical = 0
	choice_scroll.scroll_vertical = 0
	for child in options.get_children():
		options.remove_child(child)
		child.queue_free()
	var choices: Array = session.choices()
	if choices.is_empty():
		_button("Close", func() -> void: dismiss_requested.emit())
	for index in range(choices.size()):
		_button(choices[index].text, func() -> void: choice_selected.emit(index))
	options.get_child(0).grab_focus()
	# Explicit neighbors keep navigation inside this response list, including wraparound.
	var buttons := options.get_children()
	for index in range(buttons.size()):
		var button: Button = buttons[index]
		button.focus_neighbor_top = button.get_path_to(buttons[posmod(index - 1, buttons.size())])
		button.focus_neighbor_bottom = button.get_path_to(buttons[(index + 1) % buttons.size()])
	hint.hide()

func _button(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size.y = 32
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_entered.connect(func() -> void: _ensure_visible.call_deferred(button))
	button.pressed.connect(callback)
	options.add_child(button)

func close() -> void:
	panel.hide()
	hint.show()

func _layout() -> void:
	var inset := minf(32, root.size.x * 0.04)
	panel.offset_left = inset
	panel.offset_right = -inset
	panel.offset_top = -minf(380, maxf(210, root.size.y * 0.48)) - 24
	panel.offset_bottom = -24

func _ensure_visible(button: Control) -> void:
	if is_instance_valid(button) and choice_scroll.is_ancestor_of(button):
		choice_scroll.ensure_control_visible(button)
