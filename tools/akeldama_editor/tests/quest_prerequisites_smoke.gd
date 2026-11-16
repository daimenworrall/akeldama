extends SceneTree
const Editor = preload("res://app/Editor.tscn")
const Prerequisites = preload("res://story/quest_prerequisites_form.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var editor := Editor.instantiate()
	root.add_child(editor)
	await process_frame
	var workspace = editor.story
	workspace.category.select(0)
	workspace.selected = 2
	workspace.refresh()
	var form = workspace.form_host.get_child(0)
	var checkbox: CheckBox
	for child in form.get_children():
		if child.get_script() == Prerequisites:
			for field in child.get_children():
				if field is CheckBox and field.text == "Read the village notice":
					checkbox = field
	assert(checkbox != null and checkbox.button_pressed)
	checkbox.button_pressed = false
	assert(workspace.document.catalog.quest("confirm_notice").prerequisites.is_empty())
	workspace.document.undo()
	workspace.refresh()
	assert("read_notice" in workspace.document.catalog.quest("confirm_notice").prerequisites)
	assert(workspace.document.save(workspace.entity_index.ids, "user://prerequisites_test.tres").is_empty())
	var restored = ResourceLoader.load("user://prerequisites_test.tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	assert(restored.quest("confirm_notice").prerequisites == PackedStringArray(["read_notice"]))
	workspace.document.catalog.quest("read_notice").prerequisites = PackedStringArray(["confirm_notice"])
	assert(workspace.document.save(workspace.entity_index.ids, "user://prerequisites_test.tres").contains("cycle"))
	workspace.preview.quest_id = "confirm_notice"
	workspace.preview.state = "active"
	workspace.preview.start(restored, restored.conversation("professor_intro"))
	assert(workspace.preview.journal.state("read_notice") == "completed")
	assert(workspace.preview.journal.state("confirm_notice") == "active")
	DirAccess.remove_absolute("user://prerequisites_test.tres")
	editor.queue_free()
	await process_frame
	print("PASS: prerequisite checkbox editing, undo, save/load, cycle rejection and prerequisite-aware conversation preview")
	quit()
