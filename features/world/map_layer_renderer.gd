extends RefCounted
## Builds runtime tile layers from authored data.
const Objects = preload("res://features/world/objects/object_renderer.gd")
const Layer = preload("res://features/world/map_layer.gd")

static func tileset(texture: Texture2D) -> TileSet:
	var result := TileSet.new()
	result.tile_size = Vector2i(64, 64)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(64, 64)
	for y in range(texture.get_height() / 64):
		for x in range(texture.get_width() / 64):
			atlas.create_tile(Vector2i(x, y))
	result.add_source(atlas, 0)
	return result

static func add_overlays(parent: TileMapLayer, layers: Array, depth_parent: Node2D = null) -> void:
	var base_index := 0
	for index in range(layers.size()):
		if layers[index].kind == Layer.Kind.TERRAIN:
			base_index = index
	for index in range(layers.size()):
		var data: Layer = layers[index]
		if data.kind == Layer.Kind.TERRAIN:
			continue
		var node := TileMapLayer.new()
		node.name = "Layer%d" % index
		if data.kind == Layer.Kind.TILES:
			node.tile_set = tileset(data.texture)
		node.visible = data.visible
		if data.kind == Layer.Kind.OBJECTS:
			node.modulate.a = data.opacity
		else:
			node.self_modulate.a = data.opacity
		node.show_behind_parent = index < base_index
		for cell: Vector2i in data.cells:
			node.set_cell(cell, 0, data.cells[cell])
		if data.kind == Layer.Kind.OBJECTS:
			var sorted_layer: Node2D
			if depth_parent != null:
				sorted_layer = Node2D.new()
				sorted_layer.name = "DepthLayer%d" % index
				sorted_layer.y_sort_enabled = true
				sorted_layer.visible = data.visible
				sorted_layer.modulate.a = data.opacity
				depth_parent.add_child.call_deferred(sorted_layer)
			Objects.populate(node, data.objects, sorted_layer)
		parent.add_child(node)
