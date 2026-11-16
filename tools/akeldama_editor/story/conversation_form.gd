extends VBoxContainer
## Coordinates graph editing and a selected-card inspector, without runtime rules.
signal edited
signal rebuild_requested
const Fields = preload("res://story/story_fields.gd")
const Card = preload("res://story/dialogue_graph_card.gd")
const Inspector = preload("res://story/dialogue_inspector.gd")
const DialogueNode = preload("res://features/dialogue/dialogue_node.gd")
var document: RefCounted
var conversation: Resource
var selected_node := 0
var graph := GraphEdit.new()
var inspector := Inspector.new()
var delete_dialog := ConfirmationDialog.new()
var _pending_delete: Array[StringName] = []

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var header := HBoxContainer.new()
	add_child(header)
	Fields.button(header, "Add dialogue", _add_node)
	Fields.button(header, "Delete selected", func() -> void:
		_request_delete([StringName("Card%d" % selected_node)]))
	Fields.button(header, "Arrange", _arrange)
	Fields.button(header, "Fit", _frame_all)
	var title_input := LineEdit.new()
	title_input.text = conversation.title
	title_input.placeholder_text = "Conversation title"
	title_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_input.text_changed.connect(func(value: String) -> void:
		document.edit(conversation, &"title", value)
		edited.emit())
	header.add_child(title_input)
	Fields.label(self, "Connect gold → blue. No wire = end. Right-click socket: disconnect. Middle-drag: pan. Wheel: zoom.")
	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(body)
	graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph.custom_minimum_size = Vector2(320, 360)
	graph.right_disconnects = true
	graph.show_arrange_button = false
	graph.zoom = 0.75
	graph.minimap_enabled = false
	graph.connection_request.connect(_connect)
	graph.disconnection_request.connect(_disconnect)
	graph.node_selected.connect(_select)
	graph.delete_nodes_request.connect(_request_delete)
	graph.begin_node_move.connect(func() -> void: document.checkpoint())
	graph.end_node_move.connect(_save_positions)
	body.add_child(graph)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 290
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inspector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector.document = document
	inspector.conversation = conversation
	inspector.edited.connect(func() -> void: _refresh_cards(); edited.emit())
	inspector.structure_changed.connect(func() -> void: _build(); edited.emit())
	scroll.add_child(inspector)
	body.add_child(scroll)
	delete_dialog.dialog_text = "Delete the selected dialogue? Responses leading to it will end the conversation. Undo restores the nodes and connections."
	delete_dialog.confirmed.connect(_delete)
	add_child(delete_dialog)
	_build()
	await get_tree().process_frame
	_frame_all()

func _build() -> void:
	graph.clear_connections()
	for child in graph.get_children():
		if child is GraphNode:
			graph.remove_child(child)
			child.queue_free()
	for index in range(conversation.nodes.size()):
		var card := Card.new()
		card.name = "Card%d" % index
		card.data = conversation.nodes[index]
		card.position_offset = card.data.graph_position if card.data.has_graph_position else _default_position(index)
		graph.add_child(card)
		card.refresh()
	_refresh_connections()
	selected_node = clampi(selected_node, 0, maxi(0, conversation.nodes.size() - 1))
	_show_node()

func _refresh_cards() -> void:
	for child in graph.get_children():
		if child is Card:
			child.refresh()
	_refresh_connections()

func _refresh_connections() -> void:
	graph.clear_connections()
	for index in range(conversation.nodes.size()):
		for port in range(conversation.nodes[index].choices.size()):
			var target: String = conversation.nodes[index].choices[port].next_node
			for destination in range(conversation.nodes.size()):
				if conversation.nodes[destination].id == target:
					graph.connect_node("Card%d" % index, port, "Card%d" % destination, 0)

func _select(card: Node) -> void:
	selected_node = int(String(card.name).trim_prefix("Card"))
	_show_node()

func _show_node() -> void:
	inspector.selected_node = selected_node
	inspector.display()

func _data(name: StringName) -> Resource:
	var index := int(String(name).trim_prefix("Card"))
	return conversation.nodes[index] if index >= 0 and index < conversation.nodes.size() else null

func highlight(id: String) -> void:
	for child in graph.get_children():
		if child is Card:
			child.modulate = Color("ffe3a0") if child.data.id == id else Color.WHITE

func _connect(from: StringName, port: int, to: StringName, _input: int) -> void:
	var source := _data(from)
	var target := _data(to)
	if source == null or target == null or port < 0 or port >= source.choices.size():
		return
	document.edit(source.choices[port], &"next_node", target.id)
	_refresh_cards()
	edited.emit()

func _disconnect(from: StringName, port: int, to: StringName, _input: int) -> void:
	var source := _data(from)
	var target := _data(to)
	if source == null or target == null or port < 0 or port >= source.choices.size():
		return
	if source.choices[port].next_node == target.id:
		document.edit(source.choices[port], &"next_node", "")
		_refresh_cards()
		edited.emit()

func _save_positions() -> void:
	for child in graph.get_children():
		if child is Card:
			child.data.graph_position = child.position_offset
			child.data.has_graph_position = true
	edited.emit()

func _default_position(index: int) -> Vector2:
	return Vector2(40 + (index % 3) * 360, 100 + (index / 3) * 420)

func _arrange() -> void:
	document.checkpoint()
	for index in range(conversation.nodes.size()):
		graph.get_node("Card%d" % index).position_offset = _default_position(index)
	_save_positions()

func _frame_all() -> void:
	var bounds := Rect2()
	var first := true
	for child in graph.get_children():
		if child is Card:
			var rect := Rect2(child.position_offset, child.size)
			bounds = rect if first else bounds.merge(rect)
			first = false
	if first or not bounds.has_area():
		return
	var available := graph.size - Vector2(80, 100)
	graph.zoom = clampf(minf(available.x / bounds.size.x, available.y / bounds.size.y), graph.zoom_min, 1.0)
	graph.scroll_offset = bounds.position * graph.zoom - Vector2(30, 70)

func _add_node() -> void:
	document.checkpoint()
	var node := DialogueNode.new()
	node.id = "node_" + Crypto.new().generate_random_bytes(4).hex_encode()
	node.entry = conversation.nodes.is_empty()
	node.speaker = "Speaker"
	node.text = "New dialogue"
	node.graph_position = (graph.scroll_offset + graph.size * 0.3) / graph.zoom
	node.has_graph_position = true
	conversation.nodes.append(node)
	selected_node = conversation.nodes.size() - 1
	_build()
	edited.emit()

func _request_delete(names: Array[StringName]) -> void:
	_pending_delete = names
	if not names.is_empty() and not conversation.nodes.is_empty():
		delete_dialog.popup_centered()

func _delete() -> void:
	document.checkpoint()
	var removed: Array[Resource] = []
	for name in _pending_delete:
		var node := _data(name)
		if node != null:
			removed.append(node)
	for node in removed:
		conversation.nodes.erase(node)
		for remaining in conversation.nodes:
			for choice in remaining.choices:
				if choice.next_node == node.id:
					choice.next_node = ""
	_build()
	edited.emit()
