extends SceneTree
const Main = preload("res://scenes/Main.tscn")
const Story = preload("res://features/story/story_controller.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main := Main.instantiate()
	root.add_child(main)
	await process_frame
	var story: Story
	for child in main.get_node("World").get_children():
		if child is Story:
			story = child
	story.save_path = "user://journal_ui_test.json"
	story.journal.restore({})
	var event := InputEventAction.new()
	event.action = &"quest_journal"
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	assert(story.journal_screen.is_open and paused)
	var panel = story.journal_screen.panel
	assert(panel.ids.is_empty() and panel.title.text == "No active quests")
	assert(story.journal.start("read_notice") and story.journal.start("record_warning"))
	assert(panel.ids.size() == 2)
	panel.focus_default()
	assert(root.gui_get_focus_owner() == panel.list)
	var down := InputEventAction.new()
	down.action = &"ui_down"
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	assert(panel.selected_id == "record_warning")
	var player = main.get_node("World/Player")
	var position: Vector2 = player.position
	Input.action_press("move_right")
	for frame in range(3):
		await physics_frame
	Input.action_release("move_right")
	assert(player.position == position, "Journal must freeze world movement")
	panel.track_button.pressed.emit()
	assert(story.journal.tracked_id == "record_warning")
	assert(story.tracker.label.text.contains("Record the evacuation warning"))
	story.journal.interact("demo-village-noticeboard")
	assert(story.journal.complete("record_warning"))
	assert(panel.ids.size() == 1)
	panel.tabs.current_tab = 1
	assert(panel.ids.size() == 1 and panel.ids[0] == "record_warning")
	assert(not panel.track_button.visible)
	panel.reset_button.pressed.emit()
	assert(story.journal_screen.reset_dialog.visible)
	assert(story.journal_screen.reset_dialog.dialog_text.contains("Record the evacuation warning"))
	story.journal_screen.reset_dialog.get_cancel_button().pressed.emit()
	await process_frame
	assert(not story.journal_screen.reset_dialog.visible and story.journal_screen.is_open and paused, "dialog=%s journal=%s paused=%s" % [story.journal_screen.reset_dialog.visible, story.journal_screen.is_open, paused])
	assert(story.journal.state("record_warning") == "completed", "Cancelling reset changed progress")
	panel.tabs.current_tab = 0
	panel.reset_button.pressed.emit()
	assert(story.journal_screen.reset_dialog.dialog_text.contains("Confirm the evacuation route"))
	story.journal_screen.reset_dialog.get_ok_button().pressed.emit()
	assert(story.journal.state("read_notice") == "available")
	assert(story.journal.state("confirm_notice") == "locked")
	assert(panel.ids.is_empty() and not panel.reset_button.visible)
	assert(story.journal.state("record_warning") == "completed")
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	Input.parse_input_event(cancel)
	Input.flush_buffered_events()
	await process_frame
	assert(not paused and not story.journal_screen.is_open, "paused=%s journal=%s pause_menu=%s" % [paused, story.journal_screen.is_open, main.get_node("PauseLayer").overlay.visible])
	assert(not main.get_node("PauseLayer").overlay.visible, "Cancel opened Pause behind the journal")
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await process_frame
	assert(paused)
	panel.close_button.pressed.emit()
	assert(not paused)
	DirAccess.remove_absolute("user://journal_ui_test.json")
	main.queue_free()
	await process_frame
	print("PASS: journal input, empty/active/completed tabs, objective display, tracking/HUD, modal pause/focus and close behavior")
	quit()
