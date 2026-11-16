extends "res://dama/content_form.gd"
## Species tabs compose stat, progression and visual editors.
const Stats = preload("res://dama/stats_form.gd")
const Evolutions = preload("res://dama/evolutions_form.gd")
const Learnset = preload("res://dama/learnset_form.gd")
const Sheet = preload("res://dama/sheet_form.gd")
var tabs := TabContainer.new()

func _ready() -> void:
	header()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(tabs)
	var profile := HBoxContainer.new()
	profile.add_theme_constant_override("separation", 20)
	page(tabs, "Profile", profile)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile.add_child(details)
	var description := Fields.text(details, "Description", data.description, func(value: String) -> void: _edit(&"description", value), true)
	description.custom_minimum_size.x = 180
	var choices := options("types", "", true)
	for index in range(2):
		var current: String = data.types[index] if index < data.types.size() else ""
		Fields.option(details, "Primary type" if index == 0 else "Secondary type", choices.ids, choices.names, current, func(value: String) -> void:
			var types: PackedStringArray = data.types.duplicate()
			types.resize(2)
			types[index] = value
			while not types.is_empty() and types[types.size() - 1].is_empty():
				types.remove_at(types.size() - 1)
			_edit(&"types", types))
	var sheet := Sheet.new()
	sheet.document = document
	sheet.art = data.art
	sheet.folders = PackedStringArray(["res://assets/characters/dama"])
	sheet.edited.connect(func() -> void: edited.emit())
	sheet.custom_minimum_size.x = 280
	sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile.add_child(sheet)
	var stats := Stats.new()
	stats.document = document
	stats.stats = data.stats
	stats.edited.connect(func() -> void: edited.emit())
	page(tabs, "Base stats", stats)
	var evolutions := Evolutions.new()
	evolutions.document = document
	evolutions.data = data
	evolutions.edited.connect(func() -> void: edited.emit())
	page(tabs, "Evolutions", evolutions)
	var learnset := Learnset.new()
	learnset.document = document
	learnset.data = data
	learnset.edited.connect(func() -> void: edited.emit())
	page(tabs, "Moves", learnset)
