extends "res://dama/content_form.gd"
const Sheet = preload("res://dama/sheet_form.gd")
var power_input: SpinBox
var tabs := TabContainer.new()

func _ready() -> void:
	header()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(tabs)
	var rules := VBoxContainer.new()
	page(tabs, "Move rules", rules)
	Fields.text(rules, "Description", data.description, func(value: String) -> void: _edit(&"description", value), true)
	var grid := property_grid(rules)
	var types := options("types")
	Fields.option(grid, "Move type", types.ids, types.names, data.type_id, func(value: String) -> void: _edit(&"type_id", value))
	var categories := PackedStringArray(["physical", "special", "status"])
	Fields.option(grid, "Damage category", categories, categories, data.category, func(value: String) -> void:
		document.checkpoint()
		data.category = value
		data.power = 0 if value == "status" else maxi(1, data.power)
		if power_input != null:
			power_input.set_value_no_signal(data.power)
			power_input.editable = value != "status"
		edited.emit())
	power_input = Fields.number(grid, "Base power (not fixed HP damage)", data.power, 0, 999, 1, func(value: float) -> void: _edit(&"power", int(value)))
	power_input.editable = data.category != "status"
	Fields.number(grid, "Accuracy (%)", data.accuracy, 0, 100, 1, func(value: float) -> void: _edit(&"accuracy", value))
	var always := CheckBox.new()
	always.text = "Always hits (bypasses accuracy)"
	always.button_pressed = data.always_hits
	always.toggled.connect(func(value: bool) -> void: _edit(&"always_hits", value))
	Fields.label(grid, "Accuracy rule")
	grid.add_child(always)
	Fields.number(grid, "Mana points (maximum uses per Dama)", data.mana_points, 1, 999, 1, func(value: float) -> void: _edit(&"mana_points", int(value)))
	Fields.number(grid, "Priority", data.priority, -10, 10, 1, func(value: float) -> void: _edit(&"priority", int(value)))
	size_grid(grid)
	var sheet := Sheet.new()
	sheet.document = document
	sheet.art = data.animation
	sheet.optional = true
	sheet.folders = PackedStringArray(["res://assets/animations"])
	sheet.edited.connect(func() -> void: edited.emit())
	page(tabs, "Animation", sheet)
