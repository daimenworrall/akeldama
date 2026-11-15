extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(scene)
	var player = scene.get_node("World/Player")
	var map = scene.get_node("World/TileGrid")
	var terrain = player.terrain
	assert(terrain.is_walkable(player.position), "Spawn must be grass")
	assert(player.visual.offset == Vector2.ZERO, "Sprite should use its original centered pivot")
	assert(map.get_used_cells().size() > 100)
	assert(not terrain.is_walkable(Vector2(10, 5) * 64), "Pond must block movement")
	assert(not terrain.is_walkable(Vector2(9, 5) * 64), "Shoreline must block movement")
	assert(not terrain.is_walkable(Vector2(-100, -100) * 64), "Unmapped space must block movement")
	for cell: Vector2i in map.get_used_cells():
		assert(terrain.grass_mask(cell) not in [6, 9], "Demo uses unsupported diagonal-only transition")
	player.set_physics_process(false)
	player.position = Vector2(7, 5) * 64
	Input.action_press("move_right")
	player.advance_movement(2.0)
	Input.action_release("move_right")
	assert(player.position == Vector2(8, 5) * 64, "Movement crossed the shore into water")
	assert(player.visual.animation == &"idle_east", "Blocked player should face the water without walking")
	Input.action_press("move_up")
	player.advance_movement(64.0 / player.speed)
	Input.action_release("move_up")
	assert(player.position == Vector2(8, 4) * 64, "Grass movement should remain available")
	assert(terrain.is_walkable(player.position))
	print("PASS: tile map, safe spawn, blocked pond/shore/bounds, no tunnelling, grass movement")
	quit()
