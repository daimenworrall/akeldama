extends RefCounted
## Resolves a buffered foot area against straight terrain boundaries.
const Terrain = preload("res://features/world/terrain_map.gd")
const Shoreline = preload("res://features/world/shoreline_shape.gd")
const EDGE_BUFFER := 16.0
const FOOT_PROBES: Array[Vector2] = [
	Vector2.ZERO, Vector2(-6, -3), Vector2(6, -3), Vector2(-6, 3), Vector2(6, 3)]

static var buffered_probes: Array[Vector2] = _build_probes()

static func _build_probes() -> Array[Vector2]:
	var probes: Array[Vector2] = []
	var half_size := Vector2(6, 3) + Vector2.ONE * EDGE_BUFFER
	for y in [-half_size.y, 0.0, half_size.y]:
		for x in [-half_size.x, 0.0, half_size.x]:
			probes.append(Vector2(x, y))
	return probes

static func can_stand(terrain: Terrain, position: Vector2) -> bool:
	for probe in buffered_probes:
		if not _is_land(terrain, position + probe):
			return false
	return true

static func _is_land(terrain: Terrain, point: Vector2) -> bool:
	var shifted := point + Vector2(32, 32)
	var cell := Vector2i((shifted / 64.0).floor())
	var local := shifted - Vector2(cell * 64)
	return Shoreline.contains(terrain.grass_mask(cell), local)

static func move(terrain: Terrain, start: Vector2, displacement: Vector2) -> Vector2:
	if terrain == null:
		return start + displacement
	var steps := maxi(1, ceili(displacement.length()))
	var step := displacement / steps
	var position := start
	for index in range(steps):
		if can_stand(terrain, position + step):
			position += step
		else:
			position += _slide_step(terrain, position, step)
	return position

static func _slide_step(terrain: Terrain, position: Vector2, step: Vector2) -> Vector2:
	# Cancel the blocked component so diagonal input slides along a straight bank.
	var result := Vector2.ZERO
	var horizontal := Vector2(step.x, 0)
	var vertical := Vector2(0, step.y)
	if step.x != 0 and can_stand(terrain, position + horizontal):
		result += horizontal
	if step.y != 0 and can_stand(terrain, position + result + vertical):
		result += vertical
	return result
