extends VBoxContainer
## Layer controls and per-layer tilesheet/palette selection.
signal changed
signal tile_selected(tile: Vector2i)
signal object_selected(definition: Resource)
const ObjectPicker = preload("res://levels/object_picker.gd")
var object_picker: Control
var palette_scroll: ScrollContainer
const Layer = preload("res://features/world/map_layer.gd")
const Editing = preload("res://levels/layer_editing.gd")
const Palette = preload("res://levels/tile_palette.gd")
var document: RefCounted
var list := ItemList.new()
var title_input := LineEdit.new()
var shown := CheckBox.new()
var locked := CheckBox.new()
var opacity := HSlider.new()
var sheets := OptionButton.new()
var palette := Palette.new()
var paths := PackedStringArray()
var _refreshing := false
var _last_layer: Resource
var _last_sheet: Texture2D
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
	var sheet_label := Label.new()
	sheet_label.text = "Tileset (64×64 tiles)"
	add_child(sheet_label)
	_scan_sheets("res://assets/tilesets")
	for path in paths:
		sheets.add_item(path.get_file())
	sheets.item_selected.connect(_select_sheet)
	add_child(sheets)
	var hint := Label.new()
	hint.text = "Terrain: Grass / Water brushes\nTile layers: select a tile below; Erase removes it."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hint)
	object_picker = ObjectPicker.new()
	object_picker.selected.connect(func(definition: Resource) -> void: object_selected.emit(definition))
	add_child(object_picker)
	var scroll := ScrollContainer.new()
	palette_scroll = scroll
	scroll.custom_minimum_size.y = 200
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(palette)
	add_child(scroll)
	palette.tile_selected.connect(func(tile: Vector2i) -> void: tile_selected.emit(tile))

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
	sheets.disabled = terrain or layer.locked
	sheets.visible = layer.kind != Layer.Kind.OBJECTS
	object_picker.visible = layer.kind == Layer.Kind.OBJECTS
	palette_scroll.visible = layer.kind == Layer.Kind.TILES
	sheets.select(paths.find(layer.texture.resource_path))
	palette.visible = not terrain
	if _last_layer != layer or _last_sheet != layer.texture:
		palette.selected = Vector2i.ZERO
		tile_selected.emit(Vector2i.ZERO)
	_last_layer = layer
	_last_sheet = layer.texture
	palette.refresh(layer.texture)
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

func _select_sheet(index: int) -> void:
	document.checkpoint()
	var layer: Layer = document.terrain.layers[document.active_layer]
	layer.texture = load(paths[index])
	for cell: Vector2i in layer.cells.keys():
		var tile: Vector2i = layer.cells[cell]
		if tile.x >= layer.texture.get_width() / 64 or tile.y >= layer.texture.get_height() / 64:
			layer.cells.erase(cell)
	document.dirty = true
	_emit()

func _scan_sheets(path: String) -> void:
	for file in DirAccess.get_files_at(path):
		if file.get_extension().to_lower() in ["png", "webp"]:
			var texture := load(path.path_join(file)) as Texture2D
			if texture != null and texture.get_width() % 64 == 0 and texture.get_height() % 64 == 0:
				paths.append(path.path_join(file))
	for folder in DirAccess.get_directories_at(path):
		_scan_sheets(path.path_join(folder))

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
