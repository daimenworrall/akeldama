extends VBoxContainer
## Inspector for the selected dialogue card. Connections are edited on the canvas.
signal edited
signal structure_changed
const Fields = preload("res://story/story_fields.gd")
const ChoiceForm = preload("res://story/choice_form.gd")
const Choice = preload("res://features/dialogue/dialogue_choice.gd")
var document: RefCounted
var conversation: Resource
var selected_node := 0
var selected_response := 0

func display() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if conversation.nodes.is_empty():
		return
	var node = conversation.nodes[selected_node]
	Fields.label(self, "Node: " + node.id)
	Fields.text(self, "Speaker", node.speaker, func(value: String) -> void: _edit(node, &"speaker", value))
	var line := Fields.text(self, "Line", node.text, func(value: String) -> void: _edit(node, &"text", value), true)
	line.custom_minimum_size.x = 250
	var entry := CheckBox.new()
	entry.text = "Start here"
	entry.tooltip_text = "Entry conditions are tried in conversation order; the first match wins."
	entry.button_pressed = node.entry
	var rules := VBoxContainer.new()
	rules.visible = node.entry
	entry.toggled.connect(func(value: bool) -> void:
		rules.visible = value
		_edit(node, &"entry", value))
	add_child(entry)
	add_child(rules)
	var quests := PackedStringArray([""])
	for quest in document.catalog.quests:
		quests.append(quest.id)
	Fields.option(rules, "Start when quest", quests, quests, node.condition_quest, func(value: String) -> void: _edit(node, &"condition_quest", value))
	var states := PackedStringArray(["", "locked", "available", "active", "ready", "completed"])
	Fields.option(rules, "Is (blank = always)", states, states, node.condition_state, func(value: String) -> void: _edit(node, &"condition_state", value))
	Fields.label(self, "Player responses")
	var responses := OptionButton.new()
	for choice in node.choices:
		responses.add_item(choice.text)
	responses.clip_text = true
	selected_response = clampi(selected_response, 0, maxi(0, node.choices.size() - 1))
	if not node.choices.is_empty():
		responses.select(selected_response)
	responses.item_selected.connect(func(index: int) -> void:
		selected_response = index
		display())
	add_child(responses)
	if not node.choices.is_empty():
		var choice = node.choices[selected_response]
		var form := ChoiceForm.new()
		form.document = document
		form.choice = choice
		form.conversation = conversation
		form.edited.connect(func() -> void: edited.emit())
		form.remove_requested.connect(func() -> void:
			document.checkpoint()
			node.choices.erase(choice)
			display()
			structure_changed.emit())
		add_child(form)
	Fields.button(self, "Add response", func() -> void:
		document.checkpoint()
		node.choices.append(Choice.new())
		display()
		structure_changed.emit())

func _edit(data: Resource, property: StringName, value: Variant) -> void:
	document.edit(data, property, value)
	edited.emit()
