extends VBoxContainer
## Resolves selection by persistent ID, including after undo/redo replaces resources.
signal changed
signal open_conversation_requested(id: String)
const Catalog = preload("res://features/story/content/demo_story.tres")
var document: RefCounted
var selected_id := ""
var heading := Label.new()
var identity := LineEdit.new()
var name_input := LineEdit.new()
var conversations := OptionButton.new()
var details := Label.new()
var cell_x := SpinBox.new()
var cell_y := SpinBox.new()
var _refreshing := false

func _ready() -> void:
	heading.text = "Choose Inspect, then click an object or NPC."
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(heading)
	identity.editable = false
	add_child(identity)
	var copy := Button.new()
	copy.text = "Copy entity ID"
	copy.pressed.connect(func() -> void: DisplayServer.clipboard_set(selected_id))
	add_child(copy)
	name_input.placeholder_text = "Instance name"
	name_input.text_submitted.connect(_rename)
	name_input.focus_exited.connect(func() -> void: _rename(name_input.text))
	add_child(name_input)
	conversations.item_selected.connect(_assign)
	add_child(conversations)
	var open := Button.new()
	open.text = "Open conversation in Story"
	open.pressed.connect(func() -> void:
		var placed := selected()
		if placed != null and not placed.conversation_id.is_empty():
			open_conversation_requested.emit(placed.conversation_id))
	add_child(open)
	var coordinates := HBoxContainer.new()
	for input in [cell_x, cell_y]:
		input.min_value = -4096
		input.max_value = 4096
		input.step = 1
		coordinates.add_child(input)
	add_child(coordinates)
	var move := Button.new()
	move.text = "Move to cell (X, Y)"
	move.pressed.connect(_move)
	add_child(move)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(details)

func selected() -> Resource:
	if document.terrain != null:
		for layer in document.terrain.layers:
			for placed in layer.objects:
				if placed.entity_id == selected_id:
					return placed
	return null

func refresh() -> void:
	_refreshing = true
	var placed := selected()
	identity.text = selected_id if placed != null else ""
	name_input.editable = placed != null
	conversations.disabled = placed == null
	conversations.clear()
	conversations.add_item("No conversation")
	conversations.set_item_metadata(0, "")
	# Read current on-disk content after Story saves, without stale cached assignments.
	var catalog = ResourceLoader.load(Catalog.resource_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	for conversation in catalog.conversations:
		conversations.add_item(conversation.title)
		var index := conversations.item_count - 1
		conversations.set_item_metadata(index, conversation.id)
		if placed != null and placed.conversation_id == conversation.id:
			conversations.select(index)
	if placed != null:
		heading.text = placed.definition.title
		name_input.text = placed.display_name
		cell_x.value = placed.cell.x
		cell_y.value = placed.cell.y
		details.text = "Cell: %s\nConversation: %s\nRename with Enter. Use Story to edit conversations and quests." % [placed.cell, placed.conversation_id]
		for quest in catalog.quests:
			if placed.entity_id in quest.targets:
				details.text += "\nQuest target: " + quest.title
	else:
		heading.text = "Choose Inspect, then click an object or NPC."
		name_input.text = ""
		details.text = ""
	_refreshing = false

func _rename(value: String) -> void:
	var placed := selected()
	if _refreshing or placed == null or placed.display_name == value or not _editable(placed):
		return
	document.checkpoint()
	placed.display_name = value
	document.dirty = true
	changed.emit()

func _assign(index: int) -> void:
	var placed := selected()
	if _refreshing or placed == null or not _editable(placed):
		return
	document.checkpoint()
	placed.conversation_id = conversations.get_item_metadata(index)
	document.dirty = true
	changed.emit()

func _editable(placed: Resource) -> bool:
	for layer in document.terrain.layers:
		if placed in layer.objects:
			return not layer.locked and layer.visible
	return false

func _move() -> void:
	var placed := selected()
	if placed == null or not _editable(placed):
		return
	var cell := Vector2i(int(cell_x.value), int(cell_y.value))
	if cell == placed.cell:
		return
	var origin: Vector2 = placed.world_origin() + Vector2((cell - placed.cell) * 64)
	var terrain = document.terrain
	var bounds := Rect2(Vector2(terrain.origin * 64) - Vector2(32, 32), Vector2(terrain.corners[0].length() - 1, terrain.corners.size() - 1) * 64)
	if not bounds.encloses(Rect2(origin, placed.definition.texture.get_size())):
		details.text = "Move rejected: artwork must stay within the map."
		return
	for layer in terrain.layers:
		if placed in layer.objects:
			for other in layer.objects:
				if other != placed and other.cell == cell:
					details.text = "Move rejected: this layer already has an object at that cell."
					return
	document.checkpoint()
	placed.cell = cell
	document.dirty = true
	changed.emit()
