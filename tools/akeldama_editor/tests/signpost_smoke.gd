extends SceneTree
const Terrain = preload("res://features/world/terrain_map.gd")
const Layer = preload("res://features/world/map_layer.gd")
const Placement = preload("res://features/world/objects/object_placement.gd")
const Movement = preload("res://features/world/terrain_movement.gd")
const Grid = preload("res://features/world/tile_grid.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var terrain := Terrain.new()
	terrain.corners = PackedStringArray(["########", "########", "########", "########", "########", "########", "########", "########"])
	var layer := Layer.new()
	layer.kind = Layer.Kind.OBJECTS
	var placed := Placement.new()
	placed.definition = load("res://features/world/objects/definitions/signpost.tres")
	placed.cell = Vector2i(3, 3)
	layer.objects.append(placed)
	terrain.layers.append(layer)
	var base := placed.collision_rect().get_center()
	assert(not Movement.can_stand(terrain, base))
	assert(Movement.can_stand(terrain, base + Vector2(0, -18)))
	assert(Movement.can_stand(terrain, base + Vector2(0, 18)))
	var start := base - Vector2(60, 0)
	assert(Movement.move(terrain, start, Vector2(120, 0)).x < base.x, "Fast movement tunneled through sign")
	layer.visible = false
	assert(Movement.can_stand(terrain, base))
	layer.visible = true
	layer.opacity = 0.6
	var world := Node2D.new()
	world.y_sort_enabled = true
	root.add_child(world)
	var grid := Grid.new()
	grid.position = Vector2(-32, -32)
	grid.terrain = terrain
	grid.depth_parent = world
	world.add_child(grid)
	await process_frame
	var sorted_layer := world.get_node("DepthLayer0") as Node2D
	var sprite := sorted_layer.get_child(0) as Sprite2D
	assert(sorted_layer.y_sort_enabled and is_equal_approx(sorted_layer.modulate.a, layer.opacity))
	assert(sprite.global_position == placed.world_origin() + placed.definition.depth_anchor)
	assert(sprite.global_position + sprite.offset == placed.world_origin(), "Sorting moved the artwork")
	assert(sprite.z_index == 0 and sorted_layer.z_index == 0)
	print("PASS: sign base collision, fast movement, front/back clearance, visibility, depth anchor and artwork alignment")
	quit()
