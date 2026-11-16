@tool
extends Resource
@export var species_id := ""
@export var nickname := ""
@export var level := 5
## Empty means the latest four moves learned at this level.
@export var moves := PackedStringArray()
