extends "res://dama/content_form.gd"
## One authoritative defensive matchup chart; offensive views derive from it.
var summary := Label.new()

func _ready() -> void:
	header()
	var color := ColorPickerButton.new()
	color.color = data.color
	color.edit_alpha = false
	color.color_changed.connect(func(value: Color) -> void: _edit(&"color", value))
	add_child(color)
	Fields.label(self, "Damage RECEIVED by " + data.title + " from each attacking type")
	Fields.label(self, "0 = immune · below 1 = resistant · 1 = neutral · above 1 = weak. Dual-type Dama multiply both defensive values.")
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(summary)
	var grid := property_grid(self)
	for attacking in document.catalog.types:
		Fields.number(grid, "Incoming " + attacking.title + " ×", float(data.incoming.get(attacking.id, 1.0)), 0, 8, 0.25, func(value: float) -> void:
			var chart: Dictionary[String, float] = data.incoming.duplicate()
			if is_equal_approx(value, 1.0):
				chart.erase(attacking.id)
			else:
				chart[attacking.id] = value
			_edit(&"incoming", chart)
			_summary())
	size_grid(grid)
	_summary()

func _summary() -> void:
	var weaknesses := PackedStringArray()
	var resistances := PackedStringArray()
	var immune := PackedStringArray()
	for attacking in document.catalog.types:
		var value := float(data.incoming.get(attacking.id, 1.0))
		if value == 0:
			immune.append(attacking.title)
		elif value < 1:
			resistances.append("%s ×%s" % [attacking.title, value])
		elif value > 1:
			weaknesses.append("%s ×%s" % [attacking.title, value])
	summary.text = "Weak: %s\nResists: %s\nImmune: %s" % [", ".join(weaknesses) if not weaknesses.is_empty() else "None", ", ".join(resistances) if not resistances.is_empty() else "None", ", ".join(immune) if not immune.is_empty() else "None"]
