extends VBoxContainer
## Layer stack and selected-layer properties.
signal changed
const Layer = preload("res://features/world/map_layer.gd")
const Editing = preload("res://levels/layer_editing.gd")
var document: RefCounted
var list := ItemList.new()
var title_input := LineEdit.new()
var shown := CheckBox.new()
var locked := CheckBox.new()
var opacity := HSlider.new()
var _refreshing := false
var _opacity_drag := false
var _duplicate: Button
var _delete: Button

func _ready() -> void:
	custom_minimum_size.x = 270
	var heading := Label.new()
	heading.text = "LAYERS  (top draws last)"
	add_child(heading)
	list.custom_minimum_size.y = 160
	list.item_selected.connect(_select)
	add_child(list)
	var actions := HFlowContainer.new()
	add_child(actions)
	_add_button(actions, "+ Objects", _add_objects)
	_add_button(actions, "+", func() -> void: Editing.add(document); _emit())
	_duplicate = _add_button(actions, "Copy", func() -> void: Editing.duplicate_layer(document); _emit())
	_delete = _add_button(actions, "Delete", func() -> void: Editing.remove(document); _emit())
	_add_button(actions, "↑", func() -> void: Editing.reorder(document, 1); _emit())
	_add_button(actions, "↓", func() -> void: Editing.reorder(document, -1); _emit())
	title_input.placeholder_text = "Layer name"
	title_input.text_submitted.connect(func(value: String) -> void: _set_value("title", value))
	title_input.focus_exited.connect(func() -> void:
		if not _refreshing and title_input.text != document.terrain.layers[document.active_layer].title:
			_set_value("title", title_input.text))
	add_child(title_input)
	shown.text = "Visible"
	locked.text = "Locked"
	shown.toggled.connect(func(value: bool) -> void: _set_value("visible", value))
	locked.toggled.connect(func(value: bool) -> void: _set_value("locked", value))
	add_child(shown)
	add_child(locked)
	var opacity_label := Label.new()
	opacity_label.text = "Opacity"
	add_child(opacity_label)
	opacity.min_value = 0
	opacity.max_value = 1
	opacity.step = 0.05
	opacity.drag_started.connect(func() -> void:
		_opacity_drag = true
		document.checkpoint())
	opacity.drag_ended.connect(func(_changed: bool) -> void: _opacity_drag = false)
	opacity.value_changed.connect(func(value: float) -> void:
		if not _refreshing:
			if not _opacity_drag:
				document.checkpoint()
			document.terrain.layers[document.active_layer].opacity = value
			document.dirty = true
			changed.emit())
	add_child(opacity)

func refresh() -> void:
	if document.terrain == null:
		return
	_refreshing = true
	list.clear()
	for index in range(document.terrain.layers.size() - 1, -1, -1):
		var data: Layer = document.terrain.layers[index]
		list.add_item(("◉ " if data.visible else "○ ") + data.title + (" [locked]" if data.locked else ""))
	list.select(document.terrain.layers.size() - 1 - document.active_layer)
	var layer: Layer = document.terrain.layers[document.active_layer]
	title_input.text = layer.title
	shown.set_pressed_no_signal(layer.visible)
	locked.set_pressed_no_signal(layer.locked)
	opacity.set_value_no_signal(layer.opacity)
	var terrain := layer.kind == Layer.Kind.TERRAIN
	_duplicate.disabled = terrain
	_delete.disabled = terrain
	_refreshing = false

func _select(index: int) -> void:
	document.active_layer = document.terrain.layers.size() - 1 - index
	_emit()

func _set_value(property: StringName, value: Variant) -> void:
	if _refreshing:
		return
	document.checkpoint()
	document.terrain.layers[document.active_layer].set(property, value)
	document.dirty = true
	_emit()

func _emit() -> void:
	refresh()
	changed.emit()

func _add_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _add_objects() -> void:
	Editing.add(document)
	var layer: Layer = document.terrain.layers[document.active_layer]
	layer.kind = Layer.Kind.OBJECTS
	layer.title = "Objects"
	_emit()
