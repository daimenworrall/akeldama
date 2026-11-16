@tool
extends Resource
const Stats = preload("res://features/dama/data/base_stats.gd")
const Evolution = preload("res://features/dama/data/level_evolution.gd")
const Learn = preload("res://features/dama/data/learnset_entry.gd")
const Art = preload("res://features/dama/data/sheet_animation.gd")
@export var id := ""
@export var title := "New Dama"
@export_multiline var description := ""
@export var types := PackedStringArray()
@export var stats: Stats = Stats.new()
@export var evolutions: Array[Evolution] = []
@export var learnset: Array[Learn] = []
@export var art: Art = Art.new()
