extends "res://dama/content_form.gd"
## Level-up learning schedule, stored independently of a creature's equipped moves.
const Learn = preload("res://features/dama/data/learnset_entry.gd")

func _ready() -> void:
	_build()

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	Fields.label(self, "Level-up move set")
	var choices := options("moves")
	var entries: Array = data.learnset.duplicate()
	entries.sort_custom(func(a: Resource, b: Resource) -> bool: return a.level < b.level)
	for entry in entries:
		Fields.option(self, "Learns move", choices.ids, choices.names, entry.move_id, func(value: String) -> void:
			document.edit(entry, &"move_id", value)
			edited.emit())
		Fields.number(self, "At level", entry.level, 1, 100, 1, func(value: float) -> void:
			document.edit(entry, &"level", int(value))
			edited.emit())
		Fields.button(self, "Remove learned move", func() -> void:
			document.checkpoint()
			data.learnset.erase(entry)
			_build()
			edited.emit())
		add_child(HSeparator.new())
	var add := Fields.button(self, "Add learned move", func() -> void:
		document.checkpoint()
		var entry := Learn.new()
		entry.move_id = choices.ids[0]
		data.learnset.append(entry)
		_build()
		edited.emit())
	add.disabled = choices.ids.is_empty()
	Fields.label(self, "Level 1 entries are starting moves. This defines what can be learned; equipped move slots will belong to individual Dama.")
