extends RefCounted
## Straight marching-square edges from terrain corners, independent of artwork.
## Coordinates are inside a 64px tile; transitions meet at edge midpoints.
static func contains(mask: int, point: Vector2) -> bool:
	match mask:
		15:
			return true
		1:
			return point.x + point.y <= 32
		2:
			return point.x - point.y >= 32
		4:
			return point.y - point.x >= 32
		8:
			return point.x + point.y >= 96
		3:
			return point.y <= 32
		5:
			return point.x <= 32
		10:
			return point.x >= 32
		12:
			return point.y >= 32
		7:
			return point.x + point.y <= 96
		11:
			return point.y - point.x <= 32
		13:
			return point.x - point.y <= 32
		14:
			return point.x + point.y >= 32
	return false
