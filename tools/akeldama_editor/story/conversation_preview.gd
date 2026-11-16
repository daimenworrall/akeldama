extends AcceptDialog
signal node_visited(id: String)
## Runs a disposable journal/session so testing never changes game progress.
const Journal = preload("res://features/quests/quest_journal.gd")
const Session = preload("res://features/dialogue/conversation_session.gd")
const Fields = preload("res://story/story_fields.gd")
var journal := Journal.new()
var session := Session.new()
var body := VBoxContainer.new()
var lines: VBoxContainer
var definition: Resource
var quest_id := ""
var state := "available"

func _ready() -> void:
	title = "Conversation preview — simulated progress"
	min_size = Vector2i(600, 450)
	add_child(body)
	confirmed.connect(hide)
	visibility_changed.connect(func() -> void:
		if not visible:
			node_visited.emit(""))
	session.journal = journal
	session.updated.connect(_show_line)
	session.closed.connect(func() -> void:
		node_visited.emit("")
		_clear_lines()
		Fields.label(lines, "Conversation ended. Restart to test another path."))

func start(catalog: Resource, conversation: Resource) -> void:
	journal.catalog = catalog
	definition = conversation
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	var quests := PackedStringArray([""])
	for quest in catalog.quests:
		quests.append(quest.id)
	Fields.option(body, "Simulate quest", quests, quests, quest_id, func(value: String) -> void: quest_id = value)
	var states := PackedStringArray(["locked", "available", "active", "ready", "completed"])
	Fields.option(body, "Starting state", states, states, state, func(value: String) -> void: state = value)
	Fields.button(body, "Restart preview", _restart)
	lines = VBoxContainer.new()
	body.add_child(lines)
	_restart()
	popup_centered()

func _restart() -> void:
	journal.progress.clear()
	journal.completed.clear()
	journal.tracked_id = ""
	if journal.catalog.quest(quest_id) != null and state != "locked":
		_complete_prerequisites(quest_id, {})
	if journal.catalog.quest(quest_id) != null and state not in ["locked", "available"]:
		journal.start(quest_id)
		if state in ["ready", "completed"]:
			for target in journal.catalog.quest(quest_id).targets:
				journal.interact(target)
		if state == "completed":
			journal.complete(quest_id)
	if not session.begin(definition):
		_clear_lines()
		Fields.label(lines, "No entry matches this quest state.")

func _clear_lines() -> void:
	for child in lines.get_children():
		lines.remove_child(child)
		child.queue_free()

func _show_line() -> void:
	node_visited.emit(session.current.id)
	_clear_lines()
	Fields.label(lines, session.current.speaker)
	Fields.label(lines, session.current.text)
	var choices: Array = session.choices()
	for index in range(choices.size()):
		Fields.button(lines, choices[index].text, func() -> void: session.choose(index))
	if choices.is_empty():
		Fields.button(lines, "End", session.close)

func _complete_prerequisites(id: String, visited: Dictionary) -> void:
	if visited.has(id):
		return
	visited[id] = true
	var quest = journal.catalog.quest(id)
	if quest == null:
		return
	for prerequisite in quest.prerequisites:
		_complete_prerequisites(prerequisite, visited)
		var required = journal.catalog.quest(prerequisite)
		if required != null and journal.start(prerequisite):
			for target in required.targets:
				journal.interact(target)
			journal.complete(prerequisite)
