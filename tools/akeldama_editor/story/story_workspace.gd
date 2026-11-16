extends VBoxContainer
## Story selection, forms and validated save; map and story histories stay separate.
const Document = preload("res://story/story_document.gd")
const Fields = preload("res://ui/content_fields.gd")
const QuestForm = preload("res://story/quest_form.gd")
const ConversationForm = preload("res://story/conversation_form.gd")
const Preview = preload("res://story/conversation_preview.gd")
const Index = preload("res://story/entity_index.gd")
const Quest = preload("res://features/quests/quest_definition.gd")
const Conversation = preload("res://features/dialogue/conversation_definition.gd")
var document := Document.new()
var level_document: RefCounted
var list := ItemList.new()
var category := OptionButton.new()
var form_host := VBoxContainer.new()
var status := Label.new()
var preview := Preview.new()
var selected := 0
var entity_index: Dictionary
var form_scroll: ScrollContainer

func _ready() -> void:
	document.open()
	var toolbar := HBoxContainer.new()
	add_child(toolbar)
	Fields.button(toolbar, "Save story", _save)
	Fields.button(toolbar, "Undo", func() -> void: document.undo(); refresh())
	Fields.button(toolbar, "Redo", func() -> void: document.redo(); refresh())
	Fields.button(toolbar, "New", _new_resource)
	Fields.button(toolbar, "Preview conversation", _preview)
	category.add_item("Quests")
	category.add_item("Conversations")
	category.select(1)
	category.item_selected.connect(func(_index: int) -> void: selected = 0; refresh())
	toolbar.add_child(category)
	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(body)
	list.custom_minimum_size.x = 180
	list.item_selected.connect(func(index: int) -> void: selected = index; _show_form())
	body.add_child(list)
	var scroll := ScrollContainer.new()
	form_scroll = scroll
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	form_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(form_host)
	body.add_child(scroll)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status)
	add_child(preview)
	preview.node_visited.connect(func(id: String) -> void:
		if category.selected == 1 and form_host.get_child_count() > 0:
			form_host.get_child(0).highlight(id))
	refresh()

func refresh() -> void:
	entity_index = Index.collect(level_document.terrain, level_document.path)
	list.clear()
	for data in _resources():
		list.add_item(data.title)
	selected = clampi(selected, 0, maxi(0, list.item_count - 1))
	if list.item_count > 0:
		list.select(selected)
	_show_form()

func _resources() -> Array:
	return document.catalog.quests if category.selected == 0 else document.catalog.conversations

func _show_form() -> void:
	for child in form_host.get_children():
		form_host.remove_child(child)
		child.queue_free()
	if _resources().is_empty():
		return
	form_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if category.selected == 0 else ScrollContainer.SCROLL_MODE_DISABLED
	var form: VBoxContainer
	if category.selected == 0:
		form = QuestForm.new()
		form.quest = _resources()[selected]
		form.entity_ids = entity_index.ids
		form.entity_names = entity_index.names
	else:
		form = ConversationForm.new()
		form.size_flags_vertical = Control.SIZE_EXPAND_FILL
		form.conversation = _resources()[selected]
	form.document = document
	form.edited.connect(_edited)
	form.rebuild_requested.connect(refresh)
	form_host.add_child(form)
	_edited()

func _edited() -> void:
	status.text = ("Unsaved story changes. " if document.dirty else "Story saved. ") + "Entity targets include the current level; save the level too when adding or changing placements."
	if selected < list.item_count and selected < _resources().size():
		list.set_item_text(selected, _resources()[selected].title)

func _save() -> void:
	entity_index = Index.collect(level_document.terrain, level_document.path)
	var error := document.save(entity_index.ids)
	status.text = "Story saved. Restart the game to load changes." if error.is_empty() else "Cannot save:\n" + error

func _new_resource() -> void:
	document.checkpoint()
	var data: Resource = Quest.new() if category.selected == 0 else Conversation.new()
	data.id = "quest_" if category.selected == 0 else "conversation_"
	data.id += Crypto.new().generate_random_bytes(4).hex_encode()
	if category.selected == 0:
		document.catalog.quests.append(data)
	else:
		document.catalog.conversations.append(data)
	selected = _resources().size() - 1
	refresh()

func _preview() -> void:
	if category.selected == 1 and not _resources().is_empty():
		preview.start(document.catalog, _resources()[selected])
	else:
		status.text = "Choose Conversations and select a conversation to preview."

func open_conversation(id: String) -> void:
	category.select(1)
	for index in range(document.catalog.conversations.size()):
		if document.catalog.conversations[index].id == id:
			selected = index
			refresh()
			return
	status.text = "Conversation not found: " + id
