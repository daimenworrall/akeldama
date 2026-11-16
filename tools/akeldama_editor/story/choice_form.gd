extends VBoxContainer
## One player response, branch destination, condition and optional quest action.
signal edited
signal remove_requested
const Fields = preload("res://ui/content_fields.gd")
var document: RefCounted
var choice: Resource
var conversation: Resource

func _ready() -> void:
	Fields.text(self, "Player response", choice.text, func(value: String) -> void: _edit(&"text", value))
	var advanced := VBoxContainer.new()
	var toggle := CheckBox.new()
	toggle.text = "Condition / action"
	toggle.button_pressed = not choice.condition_state.is_empty() or not choice.action.is_empty()
	advanced.visible = toggle.button_pressed
	toggle.toggled.connect(func(value: bool) -> void: advanced.visible = value)
	add_child(toggle)
	add_child(advanced)
	var quests := PackedStringArray([""])
	var titles := PackedStringArray(["None"])
	for quest in document.catalog.quests:
		quests.append(quest.id)
		titles.append(quest.title)
	Fields.option(advanced, "Only show for quest", quests, titles, choice.condition_quest, func(value: String) -> void: _edit(&"condition_quest", value))
	var states := PackedStringArray(["", "locked", "available", "active", "ready", "completed"])
	Fields.option(advanced, "Required state (blank = always)", states, states, choice.condition_state, func(value: String) -> void: _edit(&"condition_state", value))
	var actions := PackedStringArray(["", "start", "complete", "battle", "heal_party"])
	Fields.option(advanced, "Action", actions, PackedStringArray(["None", "Start quest", "Complete quest", "Battle this NPC's team", "Restore player party"]), choice.action, func(value: String) -> void: _edit(&"action", value))
	Fields.option(advanced, "Action quest", quests, titles, choice.action_quest, func(value: String) -> void: _edit(&"action_quest", value))
	Fields.button(self, "Remove response", func() -> void: remove_requested.emit())
	add_child(HSeparator.new())

func _edit(property: StringName, value: Variant) -> void:
	document.edit(choice, property, value)
	edited.emit()
