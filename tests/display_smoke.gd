extends SceneTree

const DisplayService = preload("res://core/display/display_manager.gd")
const PlayerController = preload("res://features/player/player.gd")
## Run with Godot --headless --path . --script res://tests/display_smoke.gd
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene: Node = preload("res://scenes/Main.tscn").instantiate()
	root.add_child(scene)
	var player: PlayerController = scene.get_node("World/Player")
	_test_display_configuration()
	await _test_camera_tracking(scene, player)
	_test_grid_movement(player)
	print("PASS: display configuration, resolution scales, grid taps/turns/held input, pixel alignment, camera settling")
	quit()

func _test_display_configuration() -> void:
	var display: DisplayService = root.get_node("DisplayManager")
	assert(root.content_scale_size == Vector2i(640, 360))
	assert(root.content_scale_mode == Window.CONTENT_SCALE_MODE_VIEWPORT)
	assert(root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_KEEP)
	assert(root.content_scale_stretch == Window.CONTENT_SCALE_STRETCH_INTEGER)
	for sample in [[Vector2i(1280, 720), 2], [Vector2i(1920, 1080), 3], [Vector2i(2560, 1440), 4], [Vector2i(3840, 2160), 6], [Vector2i(1280, 800), 2], [Vector2i(1500, 900), 2]]:
		assert(display.integer_scale_for_size(sample[0]) == sample[1])

func _test_camera_tracking(scene: Node, player: PlayerController) -> void:
	var camera: Camera2D = scene.get_node("World/Camera2D")
	var visual: Node2D = player.get_node("Visual")
	var start := player.position
	Input.action_press("move_right")
	for frame in range(30):
		await physics_frame
		await process_frame
		assert(camera.position == camera.position.round(), "Subpixel camera position")
		assert(visual.global_position == visual.global_position.round(), "Subpixel artwork position")
	Input.action_release("move_right")
	assert(player.position.x > start.x, "Player did not move")
	for frame in range(120):
		await physics_frame
		await process_frame
	assert(camera.position.distance_to(player.position) <= 1.0, "Camera did not settle")
	assert(not camera.position_smoothing_enabled)

func _test_grid_movement(player: PlayerController) -> void:
	# Deterministic steps verify taps finish, turns wait, and diagonals never occur.
	player.set_physics_process(false)
	var origin := player.position
	Input.action_press("move_right")
	player.advance_movement(0.05)
	assert(player.position.x > origin.x and player.position.x < origin.x + 32)
	Input.action_release("move_right")
	player.advance_movement(0.5)
	assert(player.position == origin + Vector2(32, 0), "Tap did not finish exactly one tile")
	origin = player.position
	Input.action_press("move_right")
	player.advance_movement(0.125)
	Input.action_release("move_right")
	Input.action_press("move_down")
	player.advance_movement(0.125)
	assert(player.position == origin + Vector2(32, 0), "Turn happened mid-tile")
	player.advance_movement(0.25)
	assert(player.position == origin + Vector2(32, 32), "Turn did not begin at the next tile")
	Input.action_press("move_right")
	origin = player.position
	player.advance_movement(0.25)
	assert(player.position == origin + Vector2(32, 0), "Diagonal movement occurred")
	Input.action_release("move_down")
	origin = player.position
	player.advance_movement(0.5)
	assert(player.position == origin + Vector2(64, 0), "Held input did not continue across tiles")
	Input.action_release("move_right")
	assert(player.position == player.position.snapped(Vector2(32, 32)))
