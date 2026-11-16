@tool
extends Resource
const Art = preload("res://features/dama/data/sheet_animation.gd")
@export var id := ""
@export var title := "New move"
@export_multiline var description := ""
@export var type_id := ""
@export_enum("physical", "special", "status") var category := "physical"
## Base power used by a future damage calculation, not fixed HP damage.
@export var power := 40
@export var accuracy := 100.0
@export var always_hits := false
## Maximum uses of this move; each creature will own its remaining MP in battle.
@export var mana_points := 20
@export var priority := 0
@export var animation: Art = Art.new()
