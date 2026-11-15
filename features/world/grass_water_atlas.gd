extends RefCounted
## Atlas coordinates indexed by grass corners: NW, NE, SW, SE.
## Diagonal-only masks 6 and 9 fall back to water; this atlas has no such tiles.
const BY_CORNERS: Array[Vector2i] = [
	Vector2i(20, 2),
	Vector2i(1, 5),
	Vector2i(0, 5),
	Vector2i(3, 5),
	Vector2i(1, 0),
	Vector2i(1, 1),
	Vector2i(20, 2),
	Vector2i(3, 1),
	Vector2i(0, 0),
	Vector2i(20, 2),
	Vector2i(0, 1),
	Vector2i(4, 1),
	Vector2i(3, 0),
	Vector2i(9, 0),
	Vector2i(14, 0),
	Vector2i(8, 0),
]
