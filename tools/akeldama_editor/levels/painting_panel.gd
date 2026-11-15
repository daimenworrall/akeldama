extends VBoxContainer
## Tile and object choices for the active layer, independent of layer management.
signal changed
signal tile_selected(tile: Vector2i)
signal object_selected(definition: Resource)
const ObjectPicker = preload("res://levels/object_picker.gd")
const Layer = preload("res://features/world/map_layer.gd")
const Palette = preload("res://levels/tile_palette.gd")
var document: RefCounted
var active_label := Label.new()
var sheet_label := Label.new()
var object_picker: Control
var palette_scroll: ScrollContainer
var sheets := OptionButton.new()
var palette := Palette.new()
var paths := PackedStringArray()
var _last_layer: Resource
var _last_sheet: Texture2D

func _ready() -> void:
	active_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(active_label)
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
	var layer: Layer = document.terrain.layers[document.active_layer]
	var terrain := layer.kind == Layer.Kind.TERRAIN
	active_label.text = "Painting: " + layer.title + (" [locked]" if layer.locked else "")
	sheet_label.visible = layer.kind != Layer.Kind.OBJECTS
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
