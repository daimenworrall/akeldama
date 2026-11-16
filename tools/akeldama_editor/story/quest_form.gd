extends VBoxContainer
## Edits ordered interaction targets through a named-entity picker.
signal edited
signal rebuild_requested
const Fields = preload("res://ui/content_fields.gd")
const Prerequisites = preload("res://story/quest_prerequisites_form.gd")
var document: RefCounted
var quest: Resource
var entity_ids := PackedStringArray()
var entity_names := PackedStringArray()

func _ready() -> void:
	Fields.text(self, "Quest ID (stable after release)", quest.id, func(value: String) -> void: _edit(&"id", value))
	Fields.text(self, "Title", quest.title, func(value: String) -> void: _edit(&"title", value))
	Fields.text(self, "Description", quest.description, func(value: String) -> void: _edit(&"description", value), true)
	Fields.text(self, "When objectives are done", quest.completion_hint, func(value: String) -> void: _edit(&"completion_hint", value))
	var prerequisites := Prerequisites.new()
	prerequisites.document = document
	prerequisites.quest = quest
	prerequisites.edited.connect(func() -> void: edited.emit())
	add_child(prerequisites)
	Fields.label(self, "Objectives — interact with these entities in order")
	for index in range(quest.targets.size()):
		Fields.option(self, "Objective %d" % (index + 1), entity_ids, entity_names, quest.targets[index], func(value: String) -> void:
			var targets: PackedStringArray = quest.targets.duplicate()
			targets[index] = value
			_edit(&"targets", targets))
		var text: String = quest.objective_texts[index] if index < quest.objective_texts.size() else ""
		Fields.text(self, "Objective text (optional)", text, func(value: String) -> void:
			var texts: PackedStringArray = quest.objective_texts.duplicate()
			texts.resize(quest.targets.size())
			texts[index] = value
			_edit(&"objective_texts", texts))
		Fields.button(self, "Remove objective %d" % (index + 1), func() -> void:
			var targets: PackedStringArray = quest.targets.duplicate()
			targets.remove_at(index)
			var texts: PackedStringArray = quest.objective_texts.duplicate()
			if index < texts.size():
				texts.remove_at(index)
			document.checkpoint()
			quest.objective_texts = texts
			quest.targets = targets
			edited.emit()
			rebuild_requested.emit())
	var add := Fields.button(self, "Add interaction objective", func() -> void:
		var targets: PackedStringArray = quest.targets.duplicate()
		targets.append(entity_ids[0])
		_edit(&"targets", targets)
		rebuild_requested.emit())
	add.disabled = entity_ids.is_empty()

func _edit(property: StringName, value: Variant) -> void:
	document.edit(quest, property, value)
	edited.emit()
