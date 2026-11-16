extends SceneTree
const Editor = preload("res://app/Editor.tscn")
const Editing = preload("res://levels/layer_editing.gd")
const ObjectEditing = preload("res://levels/object_editing.gd")
const Document = preload("res://levels/map_document.gd")
const Validation = preload("res://features/story/story_validation.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var editor := Editor.instantiate()
	root.add_child(editor)
	await process_frame
	var levels = editor.levels
	var doc = levels.document
	var placed: Resource
	for layer in doc.terrain.layers:
		for entity in layer.objects:
			if entity.entity_id == "demo-professor":
				placed = entity
	assert(placed != null)
	levels.sidebar.current_tab = 3
	assert(levels.canvas.brush == "Inspect")
	var center: Vector2 = placed.visual_rect().get_center() - Vector2(doc.terrain.origin * 64) + Vector2(32, 32)
	levels.canvas._paint(levels.canvas.pan + center * levels.canvas.zoom)
	assert(levels.sidebar.inspector.selected_id == placed.entity_id)
	levels.sidebar.inspector._rename("Test professor")
	assert(placed.display_name == "Test professor")
	doc.undo()
	levels._refresh()
	assert(levels.sidebar.inspector.selected().display_name == "Professor")
	levels.sidebar.inspector.cell_x.value = 5
	levels.sidebar.inspector.cell_y.value = 2
	levels.sidebar.inspector._move()
	assert(levels.sidebar.inspector.selected().cell == Vector2i(5, 2))
	assert(levels.sidebar.inspector.selected().entity_id == "demo-professor")
	doc.undo()
	levels._refresh()
	doc.active_layer = 1
	placed = levels.sidebar.inspector.selected()
	ObjectEditing.stamp(doc, placed.cell, placed.definition, false, Vector2.ZERO)
	assert(doc.terrain.layers[1].objects.back() == placed, "Restamping replaced identity")
	Editing.duplicate_layer(doc)
	var original_ids := PackedStringArray()
	for entity in doc.terrain.layers[1].objects:
		original_ids.append(entity.entity_id)
	for entity in doc.terrain.layers[2].objects:
		assert(entity.entity_id not in original_ids)
	doc.undo()
	assert(doc.save("user://story_editor_map.tres") == OK)
	var restored := Document.new()
	assert(restored.open("user://story_editor_map.tres") == OK)
	assert(restored.terrain.layers[1].objects.back().entity_id == placed.entity_id)
	var story = editor.story
	story.refresh()
	assert(Validation.errors(story.document.catalog, story.entity_index.ids).is_empty())
	var title: String = story.document.catalog.quests[0].title
	story.document.edit(story.document.catalog.quests[0], &"title", "Edited quest")
	assert(story.document.dirty)
	story.document.undo()
	assert(story.document.catalog.quests[0].title == title)
	story.category.select(1)
	story.refresh()
	var form = story.form_host.get_child(0)
	for index in range(form.conversation.nodes.size()):
		form.selected_node = index
		form._show_node()
	story._preview()
	assert(story.preview.session.current.id == "offer")
	assert(story.preview.session.choose(0))
	assert(story.preview.journal.state("read_notice") == "active")
	assert(story.document.save(story.entity_index.ids, "user://story_editor_catalog.tres").is_empty())
	var catalog = ResourceLoader.load("user://story_editor_catalog.tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	assert(catalog.conversations[0].nodes[0].choices[0].action == "start")
	story.document.catalog.quests[0].targets = PackedStringArray(["missing-entity"])
	assert(not story.document.save(story.entity_index.ids, "user://story_editor_catalog.tres").is_empty())
	DirAccess.remove_absolute("user://story_editor_map.tres")
	DirAccess.remove_absolute("user://story_editor_catalog.tres")
	editor.queue_free()
	await process_frame
	print("PASS: inspection, rename/history, stable restamps, unique layer copies, map/story persistence, node/choice forms and isolated preview")
	quit()
