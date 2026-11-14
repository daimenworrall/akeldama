extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var layer = scene.get_node("PauseLayer")
	var menu = layer.get_node("Overlay/Center/PauseMenu")
	var settings = layer.get_node("Overlay/Center/SettingsWindow")
	var player: Node2D = scene.get_node("World/Player")
	layer.open()
	assert(paused)
	assert(menu.get_node("Content/Save").disabled)
	assert(root.gui_get_focus_owner() == menu.get_node("Content/Resume"))
	var start := player.position
	Input.action_press("move_right")
	for frame in range(5):
		await physics_frame
	assert(player.position == start, "Player moved while paused")
	Input.action_release("move_right")
	menu.settings_requested.emit()
	assert(settings.visible and not menu.visible and paused)
	assert(settings.size.x <= 640 and settings.size.y <= 360, "Settings exceed baseline viewport")
	var graphics = settings.get_node("Content/Tabs/Graphics")
	graphics.size_choice.item_selected.emit(2)
	assert(root.get_node("DisplayManager").get_windowed_size() == Vector2i(1920, 1080))
	var display = root.get_node("DisplayManager")
	for scaling_mode in range(3):
		display.set_fullscreen_scaling(scaling_mode)
		assert(display.fullscreen_scaling == scaling_mode)
		assert(root.content_scale_stretch == Window.CONTENT_SCALE_STRETCH_INTEGER)
	settings.back_requested.emit()
	assert(menu.visible and not settings.visible and paused)
	menu.resume_requested.emit()
	assert(not paused and not layer.overlay.visible)
	print("PASS: pause freezes movement, disabled save, settings navigation, focus, window preset, baseline layout")
	quit()
