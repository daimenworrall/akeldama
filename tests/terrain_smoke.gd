extends SceneTree
const Movement = preload("res://features/world/terrain_movement.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(scene)
	var player = scene.get_node("World/Player")
	var map = scene.get_node("World/TileGrid")
	var terrain = player.terrain
	assert(terrain.is_walkable(player.position), "Spawn must be grass")
	assert(player.visual.offset == Vector2(0, -26), "Sprite must anchor at its feet")
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
	assert(player.position.x > 8 * 64 and player.position.x < 10 * 64, "Player must approach the visible shore")
	assert(Movement.can_stand(terrain, player.position), "Feet entered water")
	player.advance_movement(0.01)
	assert(player.visual.animation == &"idle_east", "Blocked player should face the water without walking")
	Input.action_press("move_up")
	player.advance_movement(64.0 / player.speed)
	Input.action_release("move_up")
	assert(player.position.y < 5 * 64, "Grass movement must remain available along shore")
	assert(Movement.can_stand(terrain, player.position))
	for approach in [
		[Vector2(12, 2), Vector2(0, 300)],
		[Vector2(12, 12), Vector2(0, -300)],
		[Vector2(8, 6), Vector2(300, 0)],
		[Vector2(18, 6), Vector2(-300, 0)]]:
		var start: Vector2 = approach[0] * 64
		var displacement: Vector2 = approach[1]
		var stopped := Movement.move(terrain, start, displacement)
		assert(stopped != start and not stopped.is_equal_approx(start + displacement))
		assert(Movement.can_stand(terrain, stopped), "Footprint crossed a bank")
	var slide_start := Movement.move(terrain, Vector2(7, 5) * 64, Vector2(256, 0))
	var slide := Movement.move(terrain, slide_start, Vector2(128, 96))
	assert(Movement.can_stand(terrain, slide))
	assert(slide.y > slide_start.y, "Diagonal input must slide along a bank")
	# Reach the south bank, then travel sideways over its pixel bumps.
	var bank := Movement.move(terrain, Vector2(12, 12) * 64, Vector2(0, -300))
	for direction in [Vector2.LEFT, Vector2.RIGHT]:
		var along_bank := Movement.move(terrain, bank, direction * 96)
		assert((along_bank - bank).dot(direction) > 60, "Cardinal movement snagged on the shoreline")
		assert(Movement.can_stand(terrain, along_bank))
	# The full footprint remains buffered from the visible water.
	for probe in Movement.FOOT_PROBES:
		for index in range(16):
			var clearance := Vector2.RIGHT.rotated(index * TAU / 16.0) * 16
			assert(Movement._is_land(terrain, bank + probe + clearance))
	# A straight bank must remain freely traversable exactly at the buffer limit.
	var straight := preload("res://features/world/terrain_map.gd").new()
	straight.corners = PackedStringArray([
		"....................", "....................", "....................",
		"####################", "####################", "####################"])
	var edge := Vector2(400, 147)
	assert(Movement.can_stand(straight, edge))
	for direction in [Vector2.LEFT, Vector2.RIGHT]:
		var destination := Movement.move(straight, edge, direction * 256)
		assert(destination.is_equal_approx(edge + direction * 256), "Straight bank blocked sideways movement")
	assert(Movement.move(straight, edge, Vector2(0, -64)).is_equal_approx(edge))
	print("PASS: tile map, safe spawn, blocked pond/shore/bounds, no tunnelling, grass movement")
	quit()
