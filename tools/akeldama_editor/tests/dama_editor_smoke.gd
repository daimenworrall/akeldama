extends SceneTree
const Editor = preload("res://app/Editor.tscn")
const Stats = preload("res://dama/stats_form.gd")
const Evolutions = preload("res://dama/evolutions_form.gd")
const Learnset = preload("res://dama/learnset_form.gd")
const Sheet = preload("res://dama/sheet_form.gd")
const Validation = preload("res://features/dama/data/dama_validation.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var editor := Editor.instantiate()
	root.add_child(editor)
	await process_frame
	editor.navigation.item_selected.emit(3)
	var workspace = editor.dama
	assert(workspace.visible and not editor.levels.visible and not editor.story.visible)
	var doc = workspace.document
	assert(Validation.errors(doc.catalog).is_empty())
	var form = workspace.form_host.get_child(0)
	var stats = _find(form, Stats)
	_number(stats, "Health").value = 61
	assert(doc.catalog.find_species("cindlet").stats.health == 61 and doc.dirty)
	doc.undo()
	workspace.refresh()
	assert(doc.catalog.find_species("cindlet").stats.health == 45)
	doc.redo()
	workspace.refresh()
	assert(doc.catalog.find_species("cindlet").stats.health == 61)
	form = workspace.form_host.get_child(0)
	var evolution = _find(form, Evolutions)
	_number(evolution, "Minimum level").value = 18
	assert(doc.catalog.find_species("cindlet").evolutions[0].level == 18)
	var learnset = _find(form, Learnset)
	assert(learnset != null)
	workspace._duplicate()
	var copy = workspace.selected()
	assert(copy.id != "cindlet")
	copy.stats.attack = 99
	assert(doc.catalog.find_species("cindlet").stats.attack == 52, "Duplicate shares base stats")
	assert(not doc.remove("species", "seraphlare").is_empty())
	assert(not doc.remove("moves", "flamethrower").is_empty())
	assert(not doc.remove("types", "fire").is_empty())
	assert(doc.save("user://dama_editor_test.tres").is_empty())
	var restored = ResourceLoader.load("user://dama_editor_test.tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	assert(restored.find_species("cindlet").evolutions[0].level == 18)
	assert(restored.find_species("cindlet").stats.health == 61)
	workspace.tabs.current_tab = 1
	workspace.selected_id = "fire"
	workspace.refresh()
	form = workspace.form_host.get_child(0)
	_number(form, "Incoming Water ×").value = 3.0
	assert(doc.catalog.find_type("fire").incoming["water"] == 3.0)
	workspace.tabs.current_tab = 2
	workspace.selected_id = "slash"
	workspace.refresh()
	form = workspace.form_host.get_child(0)
	_number(form, "Mana points (maximum uses per Dama)").value = 12
	_number(form, "Accuracy (%)").value = 85
	assert(doc.catalog.find_move("slash").mana_points == 12 and doc.catalog.find_move("slash").accuracy == 85)
	var sheet = _find(form, Sheet)
	assert(sheet.preview.sprite.sprite_frames.get_frame_count(&"slash") == 8)
	sheet._select_asset("res://assets/animations/flamethrower.png")
	assert(doc.catalog.find_move("slash").animation.metadata_path.ends_with("flamethrower.json"))
	assert(sheet.preview.sprite.sprite_frames.get_frame_count(&"flamethrower-diagonal") == 10)
	workspace._new()
	var new_id: String = workspace.selected_id
	assert(doc.catalog.find_move(new_id) != null)
	assert(doc.remove("moves", new_id).is_empty())
	workspace.tabs.current_tab = 0
	workspace.search.text = "Seraphort"
	workspace.search.text_changed.emit("Seraphort")
	assert(workspace.ids.size() == 1 and workspace.selected_id == "seraphort")
	doc.catalog.find_species("seraphort").stats.health = 0
	assert(not doc.save("user://dama_editor_test.tres").is_empty())
	editor._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert(editor.close_dialog.visible, "Unsaved Dama edits were not protected on close")
	editor.close_dialog.hide()
	DirAccess.remove_absolute("user://dama_editor_test.tres")
	editor.queue_free()
	await process_frame
	print("PASS: Dama workspace/forms, stats/history, evolution levels, independent copies, guarded deletion, catalog roundtrip, type/move editing, VFX assignment, new content, search and unsaved-close handling")
	quit()

func _find(parent: Node, script: Script) -> Node:
	if parent.get_script() == script:
		return parent
	for child in parent.get_children():
		var found := _find(child, script)
		if found != null:
			return found
	return null

func _number(parent: Node, title: String) -> SpinBox:
	var children := parent.get_children()
	for index in range(children.size() - 1):
		if children[index] is Label and children[index].text == title and children[index + 1] is SpinBox:
			return children[index + 1]
	for child in children:
		var found := _number(child, title)
		if found != null:
			return found
	return null
