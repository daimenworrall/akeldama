extends TileMapLayer
## Renders terrain data using the grass/water corner atlas.
const Layers = preload("res://features/world/map_layer_renderer.gd")
const Layer = preload("res://features/world/map_layer.gd")
const TerrainMap = preload("res://features/world/terrain_map.gd")
const Atlas = preload("res://features/world/grass_water_atlas.gd")
@export var terrain: TerrainMap
var depth_parent: Node2D

func _ready() -> void:
	z_index = -1
	if terrain == null:
		return
	var show_terrain := true
	for data in terrain.layers:
		if data.kind == Layer.Kind.TERRAIN:
			show_terrain = data.visible
			self_modulate.a = data.opacity
			tile_set = Layers.tileset(data.texture)
	Layers.add_overlays(self, terrain.layers, depth_parent)
	if not show_terrain:
		return
	for y in range(-1, terrain.corners.size()):
		var width := terrain.corners[maxi(0, y)].length()
		for x in range(-1, width):
			var cell := terrain.origin + Vector2i(x, y)
			set_cell(cell, 0, Atlas.BY_CORNERS[terrain.grass_mask(cell)])
