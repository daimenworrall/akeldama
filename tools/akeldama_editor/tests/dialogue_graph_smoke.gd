extends SceneTree
const Editor = preload("res://app/Editor.tscn")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var editor := Editor.instantiate()
	root.add_child(editor)
	await process_frame
	var workspace = editor.story
	editor.levels.hide()
	workspace.show()
	workspace.category.select(1)
	workspace.refresh()
	await process_frame
	var form = workspace.form_host.get_child(0)
	var graph: GraphEdit = form.graph
	var original_count: int = form.conversation.nodes.size()
	var connections := 0
	for node in form.conversation.nodes:
		for choice in node.choices:
			if not choice.next_node.is_empty():
				connections += 1
	assert(graph.get_connection_list().size() == connections)
	assert(graph.get_node("Card0").get_output_port_count() == form.conversation.nodes[0].choices.size())
	graph.node_selected.emit(graph.get_node("Card1"))
	assert(form.selected_node == 1 and form.inspector.selected_node == 1)
	graph.connection_request.emit(&"Card0", 1, &"Card2", 0)
	assert(form.conversation.nodes[0].choices[1].next_node == "accepted")
	assert(graph.get_connection_count(&"Card0", 1) == 1, "Reconnecting must replace the previous destination")
	graph.disconnection_request.emit(&"Card0", 1, &"Card2", 0)
	assert(form.conversation.nodes[0].choices[1].next_node.is_empty())
	workspace.document.undo()
	workspace.refresh()
	form = workspace.form_host.get_child(0)
	assert(form.conversation.nodes[0].choices[1].next_node == "accepted")
	workspace.document.undo()
	workspace.refresh()
	form = workspace.form_host.get_child(0)
	assert(form.conversation.nodes[0].choices[1].next_node == "directions")
	form.graph.begin_node_move.emit()
	form.graph.get_node("Card0").position_offset = Vector2(180, 240)
	form.graph.end_node_move.emit()
	assert(form.conversation.nodes[0].graph_position == Vector2(180, 240))
	assert(workspace.document.save(workspace.entity_index.ids, "user://graph_test.tres").is_empty())
	var restored = ResourceLoader.load("user://graph_test.tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	assert(restored.conversations[0].nodes[0].has_graph_position)
	assert(restored.conversations[0].nodes[0].graph_position == Vector2(180, 240))
	var removed: Array[StringName] = [&"Card1"]
	form._request_delete(removed)
	form._delete()
	assert(form.conversation.find_node("directions") == null)
	assert(form.conversation.nodes[0].choices[1].next_node.is_empty())
	workspace.document.undo()
	workspace.refresh()
	form = workspace.form_host.get_child(0)
	assert(form.conversation.find_node("directions") != null)
	assert(form.conversation.nodes[0].choices[1].next_node == "directions")
	form._add_node()
	assert(form.conversation.nodes.size() == original_count + 1)
	assert(form.conversation.nodes.back().has_graph_position)
	workspace.document.undo()
	workspace.refresh()
	assert(workspace.document.catalog.conversations[0].nodes.size() == original_count)
	workspace._preview()
	assert(workspace.preview.session.choose(0))
	assert(workspace.preview.session.current.id == "accepted")
	DirAccess.remove_absolute("user://graph_test.tres")
	editor.queue_free()
	await process_frame
	print("PASS: graph ports/selection, reconnect/disconnect, history, layout persistence, safe node deletion, node creation and preview")
	quit()
