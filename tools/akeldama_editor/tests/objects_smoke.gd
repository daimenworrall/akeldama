extends SceneTree
const Document = preload("res://levels/map_document.gd")
const Editing = preload("res://levels/layer_editing.gd")
const ObjectEditing = preload("res://levels/object_editing.gd")
const Layer = preload("res://features/world/map_layer.gd")
const Movement = preload("res://features/world/terrain_movement.gd")
const TerrainLayer = preload("res://features/world/tile_grid.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for horizontal in [false, true]:
		var doc := Document.new()
		doc.create(10, 10)
		doc.terrain.corners.clear()
		for y in range(10):
			var row := ""
			for x in range(10):
				var axis: int = x if horizontal else y
				row += "." if axis in [3, 4] else "#"
			doc.terrain.corners.append(row)
		doc.terrain.spawn_cell = Vector2i(1, 1)
		Editing.add(doc)
		var objects = doc.terrain.layers[1]
		objects.kind = Layer.Kind.OBJECTS
		objects.opacity = 0.75
		var definition = load("res://features/world/objects/definitions/bridge_%s.tres" % ("horiz" if horizontal else "vert"))
		var cell := Vector2i(2, 4) if horizontal else Vector2i(4, 2)
		var start := Vector2(64, 256) if horizontal else Vector2(256, 64)
		var delta := Vector2(256, 0) if horizontal else Vector2(0, 256)
		assert(not Movement.move(doc.terrain, start, delta).is_equal_approx(start + delta))
		doc.checkpoint()
		ObjectEditing.stamp(doc, cell, definition, false, Vector2.ZERO)
		assert(objects.objects.size() == 1)
		assert(Movement.move(doc.terrain, start, delta).is_equal_approx(start + delta), "Bridge did not connect both banks")
		var beside := Vector2(192, 296) if horizontal else Vector2(296, 192)
		assert(not Movement.can_stand(doc.terrain, beside), "Water beside bridge became walkable")
		objects.visible = false
		assert(not Movement.can_stand(doc.terrain, Vector2(192, 256) if horizontal else Vector2(256, 192)))
		objects.visible = true
		objects.locked = true
		ObjectEditing.stamp(doc, cell, definition, true, objects.objects[0].visual_rect().get_center())
		assert(objects.objects.size() == 1)
		objects.locked = false
		assert(doc.save("user://objects_test.tres") == OK)
		var restored := Document.new()
		assert(restored.open("user://objects_test.tres") == OK)
		assert(Movement.move(restored.terrain, start, delta).is_equal_approx(start + delta))
		var map := TerrainLayer.new()
		map.terrain = restored.terrain
		root.add_child(map)
		assert(map.get_child(0).get_child_count() == 1, "Whole object sprite not rendered")
		assert(map.get_child(0).modulate.a == 0.75, "Object opacity must propagate to sprites")
		doc.checkpoint()
		ObjectEditing.stamp(doc, cell, definition, true, objects.objects[0].visual_rect().get_center())
		assert(objects.objects.is_empty())
		doc.undo()
		assert(doc.terrain.layers[1].objects.size() == 1, "Undo erase did not restore bridge")
	DirAccess.remove_absolute("user://objects_test.tres")
	print("PASS: both bridge orientations, land/deck transitions, water blocking, layer visibility/lock, save/load, whole-object rendering, erase/history")
	quit()
