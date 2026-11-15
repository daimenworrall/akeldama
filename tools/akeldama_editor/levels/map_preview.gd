extends RefCounted
## Composites the saved layer stack in the same bottom-to-top order as the game.
const Layer = preload("res://features/world/map_layer.gd")
const Atlas = preload("res://features/world/grass_water_atlas.gd")

static func draw_map(canvas: Control, map: Resource, pan: Vector2, zoom: float) -> void:
	var size := 64.0 * zoom
	for layer: Layer in map.layers:
		if not layer.visible:
			continue
		var tint: Color = map.lighting.ambient * Color(1, 1, 1, layer.opacity)
		if layer.kind == Layer.Kind.TERRAIN:
			for y in range(map.corners.size() - 1):
				for x in range(map.corners[y].length() - 1):
					var cell := Vector2i(x, y)
					var mask: int = map.grass_mask(map.origin + cell)
					_draw_tile(canvas, layer.texture, Atlas.BY_CORNERS[mask], cell, pan, size, tint)
					if mask in [6, 9]:
						canvas.draw_rect(Rect2(pan + Vector2(cell) * size, Vector2.ONE * size), Color(1, 0, 0, 0.5))
		elif layer.kind == Layer.Kind.OBJECTS:
			_draw_shadows(canvas, map, layer, pan, zoom)
			for placed in layer.objects:
				var definition = placed.definition
				var origin: Vector2 = Vector2((placed.cell - map.origin) * 64) + definition.visual_offset
				canvas.draw_texture_rect(definition.texture, Rect2(pan + origin * zoom, definition.texture.get_size() * zoom), false, tint)
		else:
			for cell: Vector2i in layer.cells:
				_draw_tile(canvas, layer.texture, layer.cells[cell], cell - map.origin, pan, size, tint)
	for y in range(map.corners.size() - 1):
		for x in range(map.corners[y].length() - 1):
			canvas.draw_rect(Rect2(pan + Vector2(x, y) * size, Vector2.ONE * size), Color(1, 1, 1, 0.1), false)

static func _draw_tile(canvas: Control, texture: Texture2D, atlas: Vector2i, cell: Vector2i, pan: Vector2, size: float, tint: Color) -> void:
	var rect := Rect2(pan + Vector2(cell) * size, Vector2.ONE * size)
	if rect.intersects(Rect2(Vector2.ZERO, canvas.size)):
		canvas.draw_texture_rect_region(texture, rect, Rect2(Vector2(atlas) * 64, Vector2(64, 64)), tint)

static func _draw_shadows(canvas: Control, map: Resource, layer: Resource, pan: Vector2, zoom: float) -> void:
	var lighting = map.lighting
	if not lighting.shadows_enabled:
		return
	for placed in layer.objects:
		var definition = placed.definition
		if not definition.casts_shadow:
			continue
		var anchor: Vector2 = definition.depth_anchor
		var origin: Vector2 = Vector2((placed.cell - map.origin) * 64) + definition.visual_offset + anchor
		var transform: Transform2D = lighting.projection(pan + origin * zoom)
		transform.x *= zoom
		transform.y *= zoom
		canvas.draw_set_transform_matrix(transform)
		canvas.draw_texture(definition.texture, -anchor, lighting.shadow_color * lighting.ambient * Color(1, 1, 1, layer.opacity))
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
