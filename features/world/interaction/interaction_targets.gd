extends RefCounted
## Finds reachable facing targets using world-space foot positions.
const Layer = preload("res://features/world/map_layer.gd")
const Movement = preload("res://features/world/terrain_movement.gd")

static func nearest(terrain: Resource, position: Vector2, facing: Vector2) -> Resource:
	var best: Resource
	var distance := 80.0
	for layer in terrain.layers:
		if layer.kind != Layer.Kind.OBJECTS or not layer.visible:
			continue
		for placed in layer.objects:
			if placed.conversation_id.is_empty():
				continue
			var delta: Vector2 = placed.interaction_position() - position
			if delta.length() >= distance or (delta.length() > 18 and facing.dot(delta.normalized()) < 0.35):
				continue
			# Stop just outside the target footprint; avoid talking across water/walls.
			var approach := position + delta.limit_length(maxf(0, delta.length() - 24))
			if not Movement.move(terrain, position, approach - position).is_equal_approx(approach):
				continue
			distance = delta.length()
			best = placed
	return best
