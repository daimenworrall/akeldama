extends RefCounted
## Object stamps and erasing share layer locks, map bounds and document history.
const Placement = preload("res://features/world/objects/object_placement.gd")
const Definition = preload("res://features/world/objects/object_definition.gd")
const Layer = preload("res://features/world/map_layer.gd")

static func stamp(document: RefCounted, cell: Vector2i, definition: Definition, erase: bool, point: Vector2) -> void:
	var layer: Layer = document.terrain.layers[document.active_layer]
	if layer.kind != Layer.Kind.OBJECTS or layer.locked or not layer.visible:
		return
	if erase:
		for index in range(layer.objects.size() - 1, -1, -1):
			if layer.objects[index].visual_rect().has_point(point):
				layer.objects.remove_at(index)
				document.dirty = true
				return
		return
	if definition == null:
		return
	var placed := Placement.new()
	placed.cell = cell
	placed.definition = definition
	var map_rect := Rect2(Vector2(document.terrain.origin * 64) - Vector2(32, 32), Vector2(document.terrain.corners[0].length() - 1, document.terrain.corners.size() - 1) * 64)
	if not map_rect.encloses(placed.visual_rect()):
		return
	for index in range(layer.objects.size()):
		if layer.objects[index].cell == cell:
			layer.objects[index] = placed
			document.dirty = true
			return
	layer.objects.append(placed)
	document.dirty = true
