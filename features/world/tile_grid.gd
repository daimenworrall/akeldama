extends TileMapLayer
## Renders terrain data using the grass/water corner atlas.
const TerrainMap = preload("res://features/world/terrain_map.gd")
const Atlas = preload("res://features/world/grass_water_atlas.gd")
@export var terrain: TerrainMap

func _ready() -> void:
	if terrain == null:
		return
	for y in range(-1, terrain.corners.size()):
		var width := terrain.corners[maxi(0, y)].length()
		for x in range(-1, width):
			var cell := terrain.origin + Vector2i(x, y)
			set_cell(cell, 0, Atlas.BY_CORNERS[terrain.grass_mask(cell)])
