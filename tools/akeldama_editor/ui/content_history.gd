extends RefCounted
## Shared undo/redo for editable content resources; owners handle persistence.
var catalog: Resource
var dirty := false
var undo_stack: Array[Resource] = []
var redo_stack: Array[Resource] = []

func checkpoint() -> void:
	undo_stack.append(catalog.duplicate(true))
	if undo_stack.size() > 100:
		undo_stack.pop_front()
	redo_stack.clear()
	dirty = true

func edit(data: Resource, property: StringName, value: Variant) -> void:
	if data.get(property) == value:
		return
	checkpoint()
	data.set(property, value)

func undo() -> void:
	if undo_stack.is_empty():
		return
	redo_stack.append(catalog.duplicate(true))
	catalog = undo_stack.pop_back()
	dirty = true

func redo() -> void:
	if redo_stack.is_empty():
		return
	undo_stack.append(catalog.duplicate(true))
	catalog = redo_stack.pop_back()
	dirty = true

