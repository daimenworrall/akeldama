@tool
extends Resource
## Terrain domain data: each character is a corner shared by four tiles.
## '#' is grass, '.' is water. Unmapped space is blocked water.
const TILE_SIZE := 64
@export var spawn_cell := Vector2i(2, 2)
@export var origin := Vector2i.ZERO
@export var corners := PackedStringArray()

func grass_mask(cell: Vector2i) -> int:
	var local := cell - origin
	var mask := 0
	var offsets := [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.ONE]
	for bit in range(4):
		var corner: Vector2i = local + offsets[bit]
		if corner.y >= 0 and corner.y < corners.size():
			var row := corners[corner.y]
			if corner.x >= 0 and corner.x < row.length() and row[corner.x] == "#":
				mask |= 1 << bit
	return mask

func is_walkable(world_position: Vector2) -> bool:
	# Player coordinates represent tile centers, including negative coordinates.
	var cell := Vector2i((world_position / TILE_SIZE + Vector2(0.5, 0.5)).floor())
	return grass_mask(cell) == 15
