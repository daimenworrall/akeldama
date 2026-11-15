extends RefCounted
## Active object surfaces can bridge otherwise blocked terrain.
const Layer = preload("res://features/world/map_layer.gd")

static func blocks_feet(terrain: Resource, feet: Rect2) -> bool:
	for layer in terrain.layers:
		if layer.kind != Layer.Kind.OBJECTS or not layer.visible:
			continue
		for placed in layer.objects:
			if placed.definition.collision.has_area() and placed.collision_rect().intersects(feet):
				return true
	return false

static func provides_support(terrain: Resource, point: Vector2) -> bool:
	for layer in terrain.layers:
		if layer.kind != Layer.Kind.OBJECTS or not layer.visible:
			continue
		for placed in layer.objects:
			if placed.definition.provides_walkway and placed.walkway_rect().has_point(point):
				return true
	return false
