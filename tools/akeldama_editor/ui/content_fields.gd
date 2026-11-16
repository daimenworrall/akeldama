extends RefCounted
## Shared content-authoring widgets; feature-specific callbacks own mutations.
static func label(parent: Control, text: String) -> Label:
	var result := Label.new()
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(result)
	return result

static func text(parent: Control, title: String, value: String, callback: Callable, multiline := false) -> Control:
	label(parent, title)
	if multiline:
		var input := TextEdit.new()
		input.text = value
		input.custom_minimum_size = Vector2(360, 100)
		input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		input.text_changed.connect(func() -> void: callback.call(input.text))
		parent.add_child(input)
		return input
	var input := LineEdit.new()
	input.text = value
	input.text_changed.connect(callback)
	parent.add_child(input)
	return input

static func option(parent: Control, title: String, ids: PackedStringArray, names: PackedStringArray, selected: String, callback: Callable) -> OptionButton:
	label(parent, title)
	var input := OptionButton.new()
	for index in range(ids.size()):
		input.add_item(names[index])
		if ids[index] == selected:
			input.select(index)
	if not selected.is_empty() and selected not in ids:
		input.add_item("Missing: " + selected)
		input.select(input.item_count - 1)
	input.item_selected.connect(func(index: int) -> void:
		if index < ids.size():
			callback.call(ids[index]))
	parent.add_child(input)
	return input

static func button(parent: Control, title: String, callback: Callable) -> Button:
	var input := Button.new()
	input.text = title
	input.pressed.connect(callback)
	parent.add_child(input)
	return input

static func number(parent: Control, title: String, value: float, minimum: float, maximum: float, step: float, callback: Callable) -> SpinBox:
	label(parent, title)
	var input := SpinBox.new()
	input.min_value = minimum
	input.max_value = maximum
	input.step = step
	input.value = value
	input.value_changed.connect(callback)
	parent.add_child(input)
	return input

static func identity(parent: Control, id: String) -> void:
	var input := LineEdit.new()
	input.text = id
	input.editable = false
	input.tooltip_text = "Stable content ID. Names can change without breaking references."
	parent.add_child(input)
