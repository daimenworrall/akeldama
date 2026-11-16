extends PanelContainer
## Presents accepted quests; intentions are emitted for tracking and closing.
signal close_requested
signal track_requested(id: String)
signal reset_requested(id: String)
const Text = preload("res://features/quests/quest_text.gd")
var journal: RefCounted
var terrain: Resource
var tabs := TabBar.new()
var list := ItemList.new()
var title := Label.new()
var description := Label.new()
var objectives := VBoxContainer.new()
var track_button := Button.new()
var close_button := Button.new()
var reset_button := Button.new()
var ids := PackedStringArray()
var selected_id := ""

func _ready() -> void:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var content := VBoxContainer.new()
	margin.add_child(content)
	var heading := HBoxContainer.new()
	content.add_child(heading)
	var label := Label.new()
	label.text = "QUEST JOURNAL"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(label)
	close_button.text = "Close · J / Esc / B"
	close_button.pressed.connect(func() -> void: close_requested.emit())
	heading.add_child(close_button)
	tabs.add_tab("Active")
	tabs.add_tab("Completed")
	tabs.tab_changed.connect(func(_index: int) -> void: selected_id = ""; refresh())
	content.add_child(tabs)
	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(body)
	list.custom_minimum_size.x = 280
	list.item_selected.connect(func(index: int) -> void: selected_id = ids[index]; _details())
	body.add_child(list)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(detail)
	for text_label in [title, description]:
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_child(text_label)
	detail.add_child(objectives)
	track_button.text = "Track quest"
	track_button.pressed.connect(func() -> void:
		track_requested.emit("" if journal.tracked_id == selected_id else selected_id))
	detail.add_child(track_button)
	reset_button.text = "Reset quest (temporary)"
	reset_button.pressed.connect(func() -> void: reset_requested.emit(selected_id))
	detail.add_child(reset_button)

func refresh() -> void:
	if journal == null:
		return
	ids.clear()
	list.clear()
	for quest in journal.catalog.quests:
		var state: String = journal.state(quest.id)
		if (tabs.current_tab == 0 and state in ["active", "ready"]) or (tabs.current_tab == 1 and state == "completed"):
			ids.append(quest.id)
			list.add_item(("★ " if journal.tracked_id == quest.id else "") + quest.title + (" · Ready" if state == "ready" else ""))
	if selected_id not in ids:
		selected_id = ids[0] if not ids.is_empty() else ""
	if not selected_id.is_empty():
		list.select(ids.find(selected_id))
	_details()

func focus_default() -> void:
	if ids.is_empty():
		close_button.grab_focus()
	else:
		list.grab_focus()

func _details() -> void:
	for child in objectives.get_children():
		objectives.remove_child(child)
		child.queue_free()
	var quest = journal.catalog.quest(selected_id)
	track_button.visible = quest != null and tabs.current_tab == 0
	reset_button.visible = quest != null
	if quest == null:
		title.text = "No active quests" if tabs.current_tab == 0 else "No completed quests"
		description.text = "Talk to people to discover quests." if tabs.current_tab == 0 else "Completed quests will appear here."
		return
	title.text = quest.title
	description.text = quest.description
	var progress := int(journal.progress.get(quest.id, 0))
	for index in range(quest.targets.size()):
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = ("✓ " if index < progress else "○ ") + Text.objective(quest, index, terrain)
		objectives.add_child(label)
	var status := Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.text = "Completed" if journal.state(quest.id) == "completed" else (quest.completion_hint if journal.state(quest.id) == "ready" else "Objectives: %d / %d" % [progress, quest.targets.size()])
	objectives.add_child(status)
	track_button.text = "Stop tracking" if journal.tracked_id == selected_id else "Track quest"
