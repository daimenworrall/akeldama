extends VBoxContainer
## Quest prerequisites use titles in the UI and stable IDs in content.
signal edited
const Fields = preload("res://ui/content_fields.gd")
var document: RefCounted
var quest: Resource

func _ready() -> void:
	Fields.label(self, "Requires completed quests (all selected quests)")
	var known := PackedStringArray()
	for other in document.catalog.quests:
		if other.id != quest.id:
			known.append(other.id)
			_choice(other.id, other.title)
	for id in quest.prerequisites:
		if id not in known:
			_choice(id, "Invalid reference: " + id)
	if known.is_empty() and quest.prerequisites.is_empty():
		Fields.label(self, "No other quests yet. Create another quest to add a prerequisite.")

func _choice(id: String, title: String) -> void:
	var checkbox := CheckBox.new()
	checkbox.text = title
	checkbox.tooltip_text = id
	checkbox.button_pressed = id in quest.prerequisites
	checkbox.toggled.connect(func(value: bool) -> void:
		var prerequisites: PackedStringArray = quest.prerequisites.duplicate()
		if value and id not in prerequisites:
			prerequisites.append(id)
		elif not value:
			prerequisites.remove_at(prerequisites.find(id))
		document.edit(quest, &"prerequisites", prerequisites)
		edited.emit())
	add_child(checkbox)
