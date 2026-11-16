extends RefCounted
## Story content editing, validation and history, independent of map history.
const Catalog = preload("res://features/story/story_catalog.gd")
const Validation = preload("res://features/story/story_validation.gd")
const PATH := "res://features/story/content/demo_story.tres"
var catalog: Catalog
var dirty := false
var undo_stack: Array[Resource] = []
var redo_stack: Array[Resource] = []

func open() -> void:
	catalog = ResourceLoader.load(PATH, "", ResourceLoader.CACHE_MODE_IGNORE).duplicate(true)
	dirty = false
	undo_stack.clear()
	redo_stack.clear()

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

func save(entity_ids: PackedStringArray, path: String = PATH) -> String:
	var errors := Validation.errors(catalog, entity_ids)
	if not errors.is_empty():
		return "\n".join(errors)
	var error := ResourceSaver.save(catalog, path)
	if error != OK:
		return error_string(error)
	dirty = false
	return ""
