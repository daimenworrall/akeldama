extends SceneTree
const Document = preload("res://levels/map_document.gd")
const Editing = preload("res://levels/layer_editing.gd")
const Renderer = preload("res://features/world/map_layer_renderer.gd")
const TerrainLayer = preload("res://features/world/tile_grid.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var doc := Document.new()
	doc.create()
	assert(doc.terrain.layers.size() == 1)
	Editing.add(doc)
	var overlay = doc.terrain.layers[1]
	overlay.title = "Details"
	overlay.opacity = 0.5
	doc.paint_tile(Vector2i(4, 4), Vector2i(8, 0), false)
	assert(overlay.cells[Vector2i(4, 4)] == Vector2i(8, 0))
	overlay.locked = true
	doc.paint_tile(Vector2i(4, 4), Vector2i.ZERO, true)
	assert(overlay.cells.size() == 1)
	overlay.locked = false
	doc.checkpoint()
	doc.paint_tile(Vector2i(4, 4), Vector2i.ZERO, true)
	assert(overlay.cells.is_empty())
	doc.undo()
	assert(doc.terrain.layers[1].cells.size() == 1)
	Editing.duplicate_layer(doc)
	assert(doc.terrain.layers.size() == 3)
	doc.terrain.layers[2].cells.clear()
	assert(doc.terrain.layers[1].cells.size() == 1, "Copy must not share cells")
	Editing.remove(doc)
	assert(doc.terrain.layers.size() == 2)
	Editing.reorder(doc, -1)
	assert(doc.active_layer == 0 and doc.terrain.layers[0].title == "Details")
	assert(doc.save("user://layers_test.tres") == OK)
	var restored := Document.new()
	assert(restored.open("user://layers_test.tres") == OK)
	assert(restored.terrain.layers[0].opacity == 0.5)
	assert(restored.terrain.layers[0].cells.size() == 1)
	var map := TerrainLayer.new()
	map.terrain = restored.terrain
	root.add_child(map)
	assert(map.get_used_cells().size() > 0)
	var rendered: TileMapLayer = map.get_child(0)
	assert(rendered.show_behind_parent and rendered.self_modulate.a == 0.5)
	assert(rendered.get_cell_atlas_coords(Vector2i(4, 4)) == Vector2i(8, 0))
	DirAccess.remove_absolute("user://layers_test.tres")
	print("PASS: layered painting, lock/erase, history, independent copy, reorder, persistence, runtime rendering")
	quit()
