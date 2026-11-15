extends VBoxContainer
## Coordinates editor controls and file dialogs; no gameplay dependencies.
const Document = preload("res://levels/map_document.gd")
const Sidebar = preload("res://levels/tools_sidebar.gd")
var sidebar: TabContainer
const Canvas = preload("res://levels/map_canvas.gd")
var document := Document.new()
var canvas: Control
var status := Label.new()
var file_dialog := FileDialog.new()
var discard_dialog := ConfirmationDialog.new()
var width_input := SpinBox.new()
var height_input := SpinBox.new()
var pending_action: Callable

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var toolbar := HBoxContainer.new()
	add_child(toolbar)
	_button(toolbar, "New", func() -> void: _guard(_new_map))
	_button(toolbar, "Open…", func() -> void: _guard(_choose_open))
	_button(toolbar, "Save", _save)
	_button(toolbar, "Save As…", _choose_save)
	_button(toolbar, "Undo", func() -> void: document.undo(); _refresh())
	_button(toolbar, "Redo", func() -> void: document.redo(); _refresh())
	var brush := OptionButton.new()
	for text in ["Grass", "Water", "Tile", "Erase", "Spawn"]:
		brush.add_item(text)
	toolbar.add_child(brush)
	brush.item_selected.connect(func(index: int) -> void: canvas.brush = brush.get_item_text(index))
	var dimensions := HBoxContainer.new()
	add_child(dimensions)
	var dimensions_label := Label.new()
	dimensions_label.text = "New map corners (width × height):"
	dimensions.add_child(dimensions_label)
	for input in [width_input, height_input]:
		input.min_value = 8
		input.max_value = 128
		input.step = 1
		dimensions.add_child(input)
	width_input.value = 41
	height_input.value = 31
	var hint := Label.new()
	hint.text = "Paint: drag • Pan: two fingers / middle-drag / Space-drag • Zoom: pinch / wheel"
	add_child(hint)
	canvas = Canvas.new()
	canvas.document = document
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.edited.connect(_refresh)
	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(canvas)
	sidebar = Sidebar.new()
	sidebar.document = document
	sidebar.changed.connect(_refresh)
	sidebar.object_selected.connect(func(definition: Resource) -> void: canvas.selected_object = definition)
	sidebar.tile_selected.connect(func(tile: Vector2i) -> void: canvas.selected_tile = tile)
	body.add_child(sidebar)
	add_child(body)
	add_child(status)
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.filters = PackedStringArray(["*.tres ; Terrain map"])
	file_dialog.current_dir = "res://features/world/maps"
	file_dialog.file_selected.connect(_file_selected)
	add_child(file_dialog)
	discard_dialog.dialog_text = "Discard unsaved map changes?"
	discard_dialog.confirmed.connect(func() -> void: pending_action.call())
	add_child(discard_dialog)
	var error := document.open("res://features/world/maps/demo.tres")
	if error != OK:
		document.create()
	_refresh()

func _button(parent: Control, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)

func _guard(action: Callable) -> void:
	if document.dirty:
		pending_action = action
		discard_dialog.popup_centered()
	else:
		action.call()

func _new_map() -> void:
	document.create(int(width_input.value), int(height_input.value))
	canvas.pan = Vector2(40, 40)
	_refresh()

func _choose_open() -> void:
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.popup_centered_ratio(0.7)

func _choose_save() -> void:
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.current_file = "new_map.tres" if document.path.is_empty() else document.path.get_file()
	file_dialog.popup_centered_ratio(0.7)

func _save() -> void:
	if document.path.is_empty():
		_choose_save()
	else:
		_write(document.path)

func _file_selected(path: String) -> void:
	if file_dialog.file_mode == FileDialog.FILE_MODE_OPEN_FILE:
		var error := document.open(path)
		if error != OK:
			status.text = "Could not open terrain map: " + error_string(error)
			return
		_refresh()
	else:
		_write(path)

func _write(path: String) -> void:
	var validation := document.validation_error()
	if not validation.is_empty():
		status.text = "Cannot save: " + validation
		return
	var error := document.save(path)
	_refresh()
	if error != OK:
		status.text = "Could not save map: " + error_string(error)


func _refresh() -> void:
	canvas.queue_redraw()
	sidebar.refresh()
	var label := "Untitled" if document.path.is_empty() else document.path
	status.text = ("* " if document.dirty else "") + label
	var validation := document.validation_error()
	if not validation.is_empty():
		status.text += " — " + validation

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.is_command_or_control_pressed() and event.keycode == KEY_S:
		if event.shift_pressed:
			_choose_save()
		else:
			_save()
		get_viewport().set_input_as_handled()
