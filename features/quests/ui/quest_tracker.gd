extends CanvasLayer
## Compact HUD for one tracked quest; the journal still advances all active quests.
const Text = preload("res://features/quests/quest_text.gd")
var label := Label.new()
var journal: RefCounted
var terrain: Resource

func _ready() -> void:
	layer = 5
	label.position = Vector2(20, 18)
	label.custom_minimum_size.x = 420
	label.size.x = 420
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

func setup(state: RefCounted, map: Resource) -> void:
	journal = state
	terrain = map
	journal.changed.connect(refresh)
	refresh()

func refresh() -> void:
	label.text = Text.hud(journal, terrain)
