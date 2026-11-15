extends RefCounted
## Mutations of the layer stack share document history with tile painting.
const Layer = preload("res://features/world/map_layer.gd")

static func add(document: RefCounted) -> void:
	document.checkpoint()
	var layer := Layer.new()
	layer.title = "Layer %d" % document.terrain.layers.size()
	document.terrain.layers.insert(document.active_layer + 1, layer)
	document.active_layer += 1
	document.dirty = true

static func duplicate_layer(document: RefCounted) -> void:
	var layer: Layer = document.terrain.layers[document.active_layer]
	if layer.kind == Layer.Kind.TERRAIN:
		return
	document.checkpoint()
	var copy: Layer = layer.duplicate(true)
	copy.title += " copy"
	document.terrain.layers.insert(document.active_layer + 1, copy)
	document.active_layer += 1
	document.dirty = true

static func remove(document: RefCounted) -> void:
	if document.terrain.layers[document.active_layer].kind == Layer.Kind.TERRAIN:
		return
	document.checkpoint()
	document.terrain.layers.remove_at(document.active_layer)
	document.active_layer = maxi(0, document.active_layer - 1)
	document.dirty = true

static func reorder(document: RefCounted, direction: int) -> void:
	var target: int = document.active_layer + direction
	if target < 0 or target >= document.terrain.layers.size():
		return
	document.checkpoint()
	var layer: Layer = document.terrain.layers.pop_at(document.active_layer)
	document.terrain.layers.insert(target, layer)
	document.active_layer = target
	document.dirty = true
