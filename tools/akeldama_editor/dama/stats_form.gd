extends VBoxContainer
signal edited
const Fields = preload("res://ui/content_fields.gd")
const Validation = preload("res://features/dama/data/dama_validation.gd")
var document: RefCounted
var stats: Resource

func _ready() -> void:
	Fields.label(self, "Base stats — values before level-based growth")
	for field in Validation.STAT_FIELDS:
		Fields.number(self, String(field).capitalize(), stats.get(field), 1, 999, 1, func(value: float) -> void:
			document.edit(stats, field, int(value))
			edited.emit())
