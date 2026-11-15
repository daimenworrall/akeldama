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
	_test_player_art(player)
	_test_display_configuration()
	await _test_camera_tracking(scene, player)
	_test_grid_movement(player)
	print("PASS: display configuration, resolution scales, grid taps/turns/held input, pixel alignment, camera settling")
	quit()

func _test_player_art(player: PlayerController) -> void:
	var visual = player.get_node("Visual")
	assert(visual.sprite_frames.get_frame_count(&"walk_south") == 6)
	var texture: AtlasTexture = visual.sprite_frames.get_frame_texture(&"walk_north", 5)
	assert(texture.region == Rect2(480, 288, 96, 96))
	visual.set_movement(Vector2.LEFT, true)
	assert(visual.animation == &"walk_east" and visual.flip_h)
	visual.set_movement(Vector2.LEFT, false)
	assert(visual.animation == &"idle_west" and not visual.flip_h)
	visual.set_movement(Vector2.DOWN, false)

func _test_display_configuration() -> void:
	var display: DisplayService = root.get_node("DisplayManager")
	assert(root.content_scale_size == Vector2i(1280, 720))
	assert(root.content_scale_mode == Window.CONTENT_SCALE_MODE_VIEWPORT)
	assert(root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_KEEP)
	assert(root.content_scale_stretch == Window.CONTENT_SCALE_STRETCH_FRACTIONAL)
	for sample in [[Vector2i(1280, 720), 1], [Vector2i(1920, 1080), 1], [Vector2i(2560, 1440), 2], [Vector2i(3840, 2160), 3], [Vector2i(1280, 800), 1], [Vector2i(1500, 900), 1]]:
		assert(display.integer_scale_for_size(sample[0]) == sample[1])

func _test_camera_tracking(scene: Node, player: PlayerController) -> void:
	var camera: Camera2D = scene.get_node("World/Camera2D")
	var visual: Node2D = player.get_node("Visual")
	var start := player.position
	Input.action_press("move_right")
	for frame in range(30):
		await physics_frame
		await process_frame
		assert(camera.position.distance_to(player.position) <= 12.0, "Camera trails too far behind movement")
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
	# Exercise movement independently of the demo map layout.
	player.terrain = null
	var step_time := 64.0 / player.speed
	var origin := player.position
	Input.action_press("move_right")
	player.advance_movement(0.05)
	assert(player.position.x > origin.x and player.position.x < origin.x + 64)
	Input.action_release("move_right")
	player.advance_movement(0.5)
	assert(player.position == origin + Vector2(64, 0), "Tap did not finish exactly one tile")
	origin = player.position
	Input.action_press("move_right")
	player.advance_movement(step_time / 2.0)
	Input.action_release("move_right")
	Input.action_press("move_down")
	player.advance_movement(step_time / 2.0)
	assert(player.position == origin + Vector2(64, 0), "Turn happened mid-tile")
	player.advance_movement(step_time)
	assert(player.position == origin + Vector2(64, 64), "Turn did not begin at the next tile")
	Input.action_press("move_right")
	origin = player.position
	player.advance_movement(step_time)
	assert(player.position == origin + Vector2(64, 0), "Diagonal movement occurred")
	Input.action_release("move_down")
	origin = player.position
	player.advance_movement(step_time * 2.0)
	assert(player.position == origin + Vector2(128, 0), "Held input did not continue across tiles")
	Input.action_release("move_right")
	assert(player.position == player.position.snapped(Vector2(64, 64)))
