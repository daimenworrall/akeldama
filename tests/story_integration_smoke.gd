extends SceneTree
const Main = preload("res://scenes/Main.tscn")
const Story = preload("res://features/story/story_controller.gd")
const Journal = preload("res://features/quests/quest_journal.gd")
const Save = preload("res://features/quests/quest_save.gd")
const TEST_PATH := "user://story_integration_progress.json"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main := Main.instantiate()
	root.add_child(main)
	await process_frame
	var world = main.get_node("World")
	var story: Story
	for child in world.get_children():
		if child is Story:
			story = child
	assert(story != null)
	story.save_path = TEST_PATH
	story.journal.restore({})
	var professor: Resource
	var sign: Resource
	for layer in world.terrain.layers:
		for placed in layer.objects:
			if placed.entity_id == "demo-professor":
				professor = placed
			if placed.entity_id == "demo-village-noticeboard":
				sign = placed
	assert(professor != null and sign != null)
	_interact(story, professor)
	assert(story.session.current.id == "offer" and not world.player.movement_enabled)
	assert(story.view.panel.visible and story.view.options.get_child_count() == story.session.choices().size())
	assert(root.gui_get_focus_owner() == story.view.options.get_child(0))
	var down := InputEventAction.new()
	down.action = &"ui_down"
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	assert(root.gui_get_focus_owner() == story.view.options.get_child(1), "Choices must support directional navigation")
	story.view.options.get_child(0).pressed.emit()
	assert(story.session.current.id == "accepted")
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	Input.parse_input_event(cancel)
	await process_frame
	assert(story.session.current == null and not paused, "Escape must close dialogue without opening pause")
	assert(world.player.movement_enabled)
	_interact(story, sign)
	assert(story.journal.state("read_notice") == "ready")
	story.view.dismiss_requested.emit()
	_interact(story, professor)
	assert(story.session.current.id == "ready")
	story.view.options.get_child(0).pressed.emit()
	assert(story.journal.state("read_notice") == "completed")
	var restored := Journal.new()
	restored.catalog = story.journal.catalog
	Save.load_into(restored, TEST_PATH)
	assert(restored.state("read_notice") == "completed")
	DirAccess.remove_absolute(TEST_PATH)
	main.queue_free()
	await process_frame
	print("PASS: professor/sign proximity, dialogue buttons, movement lock, Escape/pause handling and persisted quest hand-in")
	quit()

func _interact(story: Story, placed: Resource) -> void:
	story.player.position = placed.interaction_position() + Vector2(0, 34)
	story.player._facing = Vector2.UP
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	story._unhandled_input(event)
