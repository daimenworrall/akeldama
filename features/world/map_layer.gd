@tool
extends Resource
## One authored visual layer. Terrain collision remains owned by TerrainMap.
const Placement = preload("res://features/world/objects/object_placement.gd")
enum Kind { TERRAIN, TILES, OBJECTS }
@export var objects: Array[Placement] = []
@export var title := "Tile layer"
@export var kind := Kind.TILES
@export var texture: Texture2D = preload("res://assets/tilesets/grass_water.png")
@export var visible := true
@export var locked := false
@export_range(0.0, 1.0) var opacity := 1.0
@export var cells: Dictionary[Vector2i, Vector2i] = {}
