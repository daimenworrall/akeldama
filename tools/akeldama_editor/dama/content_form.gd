extends VBoxContainer
## Shared mutation contract for Dama content panels.
signal edited
const Fields = preload("res://ui/content_fields.gd")
var document: RefCounted
var data: Resource

func header() -> void:
	Fields.identity(self, data.id)
	Fields.text(self, "Name", data.title, func(value: String) -> void: _edit(&"title", value))

func options(kind: String, excluded := "", allow_none := false) -> Dictionary:
	var result := {"ids": PackedStringArray(), "names": PackedStringArray()}
	if allow_none:
		result.ids.append("")
		result.names.append("None")
	for item in document.catalog.get(kind):
		if item.id != excluded:
			result.ids.append(item.id)
			result.names.append(item.title)
	return result

func _edit(property: StringName, value: Variant) -> void:
	document.edit(data, property, value)
	edited.emit()

func page(tabs: TabContainer, title: String, content: Control) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	tabs.add_child(scroll)

func property_grid(parent: Control) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	parent.add_child(grid)
	return grid

func size_grid(grid: GridContainer) -> void:
	for child in grid.get_children():
		if child is Label:
			child.custom_minimum_size.x = 220
		else:
			child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
