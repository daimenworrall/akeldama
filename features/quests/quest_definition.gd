@tool
extends Resource
## Ordered interaction objectives. IDs refer to placed entities, not artwork.
@export var id := ""
@export var title := "New quest"
@export var description := ""
@export var targets := PackedStringArray()
## Every listed quest must be completed before this quest can start.
@export var prerequisites := PackedStringArray()
@export var objective_texts := PackedStringArray()
@export var completion_hint := "Return to the quest giver."
