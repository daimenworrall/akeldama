extends "res://dama/content_form.gd"
## Authors level-based branches; incoming links make the whole line visible.
const Evolution = preload("res://features/dama/data/level_evolution.gd")

func _ready() -> void:
	_build()

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	Fields.label(self, "Evolution line for " + data.title)
	for species in document.catalog.species:
		for rule in species.evolutions:
			if rule.species_id == data.id:
				Fields.label(self, "%s → %s at level %d" % [species.title, data.title, rule.level])
	var choices := options("species", data.id)
	var unused: PackedStringArray = choices.ids.duplicate()
	for rule in data.evolutions:
		unused.erase(rule.species_id)
	for rule in data.evolutions:
		Fields.option(self, "Evolves into", choices.ids, choices.names, rule.species_id, func(value: String) -> void:
			document.edit(rule, &"species_id", value)
			edited.emit())
		Fields.number(self, "Minimum level", rule.level, 2, 100, 1, func(value: float) -> void:
			document.edit(rule, &"level", int(value))
			edited.emit())
		Fields.button(self, "Remove evolution", func() -> void:
			document.checkpoint()
			data.evolutions.erase(rule)
			_build()
			edited.emit())
		add_child(HSeparator.new())
	var add := Fields.button(self, "Add level evolution", func() -> void:
		document.checkpoint()
		var rule := Evolution.new()
		rule.species_id = unused[0]
		data.evolutions.append(rule)
		_build()
		edited.emit())
	add.disabled = unused.is_empty()
	Fields.label(self, "Multiple rules create branching evolutions. Missing targets and cycles prevent saving.")
