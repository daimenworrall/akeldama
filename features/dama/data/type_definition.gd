@tool
extends Resource
## Defensive chart: incoming attack type ID -> damage multiplier; absent = 1x.
@export var id := ""
@export var title := "New type"
@export var color := Color.WHITE
@export var incoming: Dictionary[String, float] = {}
