extends GraphNode
## A line's readable summary and one output port per player response.
var data: Resource

func refresh() -> void:
	_style()
	clear_all_slots()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	title = ("ENTRY · " if data.entry else "Dialogue · ") + (data.speaker if not data.speaker.is_empty() else data.id)
	var summary: String = data.text if not data.text.is_empty() else "Write a line in the inspector…"
	if data.entry:
		summary = ("When %s is %s\n" % [data.condition_quest, data.condition_state] if not data.condition_state.is_empty() else "Entry · always\n") + summary
	_row(summary, 4)
	set_slot(0, true, 0, Color("88b9dd"), false, 0, Color.WHITE)
	for index in range(data.choices.size()):
		var choice = data.choices[index]
		var text: String = choice.text
		if not choice.action.is_empty():
			text += "\n→ " + ({"battle": "Battle NPC team", "heal_party": "Restore player party"}.get(choice.action, "%s quest: %s" % [choice.action, choice.action_quest]))
		if not choice.condition_state.is_empty():
			text += "\nIf %s is %s" % [choice.condition_quest, choice.condition_state]
		if choice.next_node.is_empty():
			text += "  [End]"
		_row(text, 3)
		set_slot(index + 1, false, 0, Color.WHITE, true, 0, Color("e8c276"))
	if data.choices.is_empty():
		_row("Close → End conversation", 1)
	reset_size()

func _style() -> void:
	for key in ["panel", "panel_selected", "titlebar", "titlebar_selected"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("26394b") if key.begins_with("titlebar") else Color("18232d")
		box.border_color = Color("e8c276") if key.ends_with("selected") else Color("4b657b")
		box.set_border_width_all(2 if key.ends_with("selected") else 1)
		box.set_content_margin_all(12)
		box.set_corner_radius_all(5)
		add_theme_stylebox_override(key, box)

func _row(text: String, lines: int) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = 250
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.max_lines_visible = lines
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
