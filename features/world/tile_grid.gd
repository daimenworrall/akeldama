extends Node2D
const TILE_SIZE := 32
const EXTENT := 48

func _draw() -> void:
	for y in range(-EXTENT, EXTENT):
		for x in range(-EXTENT, EXTENT):
			var origin := Vector2(x, y) * TILE_SIZE
			var color := Color("88a86d") if (x + y) % 2 == 0 else Color("80a066")
			if x in [-1, 0] or y in [-1, 0]:
				color = Color("c7b88b")
			draw_rect(Rect2(origin, Vector2(TILE_SIZE, TILE_SIZE)), color)
			# One-pixel grid and grass marks reveal shimmer or uneven scaling.
			draw_rect(Rect2(origin, Vector2(TILE_SIZE, 1)), Color("71885b"))
			draw_rect(Rect2(origin, Vector2(1, TILE_SIZE)), Color("71885b"))
			if color != Color("c7b88b"):
				draw_rect(Rect2(origin + Vector2(12, 18), Vector2(1, 3)), Color("526e4d"))
				draw_rect(Rect2(origin + Vector2(14, 17), Vector2(1, 4)), Color("526e4d"))
