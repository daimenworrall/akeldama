@tool
extends Resource
const Choice = preload("res://features/dialogue/dialogue_choice.gd")
@export var id := ""
@export var speaker := ""
@export_multiline var text := ""
## Entry nodes are tried in order; leave the last entry unconditional.
@export var entry := false
@export var condition_quest := ""
@export var condition_state := ""
@export var choices: Array[Choice] = []
## Authoring metadata only; the conversation runtime ignores graph layout.
@export var graph_position := Vector2.ZERO
@export var has_graph_position := false
