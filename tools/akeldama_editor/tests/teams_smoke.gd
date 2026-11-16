extends SceneTree
const Editor = preload("res://app/Editor.tscn")
const MemberForm = preload("res://teams/member_form.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var editor := Editor.instantiate()
	root.add_child(editor)
	await process_frame
	editor.navigation.item_selected.emit(4)
	var workspace = editor.teams
	assert(workspace.visible and not editor.dama.visible and not editor.story.visible)
	assert(workspace.selected().members.size() == 1)
	var member_form: Control
	for child in workspace.form.get_children():
		if child.get_script() == MemberForm:
			member_form = child
	assert(member_form != null)
	for child in member_form.get_children():
		if child is SpinBox:
			child.value = 22
	assert(workspace.selected().members[0].level == 22)
	workspace.document.undo()
	workspace.refresh()
	assert(workspace.selected().members[0].level == 18)
	assert(not workspace.document.remove("professor_test", editor.levels.document).is_empty())
	workspace._duplicate()
	var copy_id: String = workspace.selected_id
	workspace.selected().members[0].level = 10
	assert(workspace.document.catalog.find_team("professor_test").members[0].level == 18)
	assert(workspace.document.save("user://teams_test.tres").is_empty())
	var saved = ResourceLoader.load("user://teams_test.tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	assert(saved.find_team(copy_id).members[0].level == 10)
	assert(workspace.document.remove(copy_id, editor.levels.document).is_empty())
	var inspector = editor.levels.sidebar.inspector
	inspector.selected_id = "demo-professor"
	inspector.refresh()
	assert(inspector.selected().team_id == "professor_test")
	inspector._assign_team(0)
	assert(inspector.selected().team_id.is_empty())
	editor.levels.document.undo()
	inspector.refresh()
	assert(inspector.selected().team_id == "professor_test")
	assert(editor.levels.document.save("user://team_assignment_test.tres") == OK)
	var map = ResourceLoader.load("user://team_assignment_test.tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	var found := false
	for layer in map.layers:
		for placed in layer.objects:
			if placed.entity_id == "demo-professor":
				assert(placed.team_id == "professor_test")
				found = true
	assert(found)
	assert(not editor.dama.document.references("species", "cindlet").is_empty())
	DirAccess.remove_absolute("user://teams_test.tres")
	DirAccess.remove_absolute("user://team_assignment_test.tres")
	editor.queue_free()
	await process_frame
	print("PASS: Teams workspace, member editing/history, independent copies, save/load, assignment undo/persistence and reference guards")
	quit()
