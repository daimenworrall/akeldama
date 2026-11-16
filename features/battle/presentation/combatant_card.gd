extends PanelContainer
## Compact creature identity/HP display, independent of turn rules.
var title := Label.new()
var health := ProgressBar.new()
var numbers := Label.new()

func _ready() -> void:
	custom_minimum_size = Vector2(310, 90)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	add_child(margin)
	var content := VBoxContainer.new()
	margin.add_child(content)
	content.add_child(title)
	health.show_percentage = false
	health.custom_minimum_size.y = 12
	var background := StyleBoxFlat.new()
	background.bg_color = Color("253442")
	health.add_theme_stylebox_override("background", background)
	content.add_child(health)
	content.add_child(numbers)

func display(creature: RefCounted, catalog: Resource, index: int, count: int) -> void:
	title.text = "%s · Lv %d   [%d/%d]" % [creature.title(catalog), creature.level, index + 1, count]
	health.max_value = creature.stats[&"health"]
	health.value = creature.health
	var fill := StyleBoxFlat.new()
	var ratio: float = float(creature.health) / creature.stats[&"health"]
	fill.bg_color = Color("70b77b") if ratio > 0.5 else (Color("ddbb60") if ratio > 0.2 else Color("d97070"))
	health.add_theme_stylebox_override("fill", fill)
	numbers.text = "HP %d / %d" % [creature.health, creature.stats[&"health"]]
