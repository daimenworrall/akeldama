extends Node2D
## Applies the authored map's spawn before child player/camera initialization.
const Player = preload("res://features/player/player.gd")
const TerrainLayer = preload("res://features/world/tile_grid.gd")
const TerrainMap = preload("res://features/world/terrain_map.gd")
@export var terrain: TerrainMap
@export var player: Player
@export var tile_grid: TerrainLayer

func _enter_tree() -> void:
	if terrain != null and player != null:
		player.terrain = terrain
		if tile_grid != null:
			tile_grid.terrain = terrain
		player.position = Vector2(terrain.spawn_cell * TerrainMap.TILE_SIZE)
