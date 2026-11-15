extends TabContainer
## Owns tool navigation; panels share the active document and layer selection.
signal changed
signal tile_selected(tile: Vector2i)
signal object_selected(definition: Resource)
const Layers = preload("res://levels/layers_panel.gd")
const Painting = preload("res://levels/painting_panel.gd")
const Lighting = preload("res://levels/lighting_panel.gd")
var document: RefCounted
var panels: Array[Control] = []

func _ready() -> void:
	name = "ToolsSidebar"
	custom_minimum_size.x = 330
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var layers := Layers.new()
	var painting := Painting.new()
	var lighting := Lighting.new()
	painting.tile_selected.connect(func(tile: Vector2i) -> void: tile_selected.emit(tile))
	painting.object_selected.connect(func(definition: Resource) -> void: object_selected.emit(definition))
	_add_tab("Layers", layers)
	_add_tab("Painting", painting)
	_add_tab("Lighting", lighting)
	current_tab = 0

func _add_tab(title: String, panel: Control) -> void:
	panel.document = document
	panel.changed.connect(func() -> void: changed.emit())
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.add_child(panel)
	panels.append(panel)
	add_child(scroll)

func refresh() -> void:
	for panel in panels:
		panel.refresh()
