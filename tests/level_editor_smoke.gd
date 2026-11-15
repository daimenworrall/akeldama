extends SceneTree
const Document = preload("res://addons/level_editor/map_document.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var document := Document.new()
	assert(document.open("res://features/world/maps/demo.tres") == OK)
	assert(document.validation_error().is_empty())
	# Use a private fixture so authoring the demo cannot break history tests.
	document.create()
	document.checkpoint()
	document.paint(Vector2i(20, 10), false)
	assert(document.terrain.corners[10][20] == ".")
	document.undo()
	assert(document.terrain.corners[10][20] == "#")
	document.redo()
	assert(document.terrain.corners[10][20] == ".")
	document.undo()
	document.terrain.spawn_cell = Vector2i(4, 3)
	assert(document.save("user://editor_test_map.tres") == OK)
	var restored := Document.new()
	assert(restored.open("user://editor_test_map.tres") == OK)
	assert(restored.terrain.corners == document.terrain.corners)
	assert(restored.terrain.spawn_cell == Vector2i(4, 3))
	var scene: Node = load("res://scenes/Main.tscn").instantiate()
	var world = scene.get_node("World")
	world.terrain = restored.terrain
	root.add_child(scene)
	assert(scene.get_node("World/Player").position == Vector2(256, 192))
	document.create(8, 8)
	assert(document.validation_error().is_empty())
	document.terrain.spawn_cell = Vector2i(-100, -100)
	assert(not document.validation_error().is_empty())
	assert(document.save("user://invalid_map.tres") == ERR_INVALID_DATA)
	DirAccess.remove_absolute("user://editor_test_map.tres")
	print("PASS: editor paint/history, resource roundtrip, authored spawn, map validation")
	quit()
