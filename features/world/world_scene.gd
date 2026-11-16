extends Node2D
## Applies the authored map's spawn before child player/camera initialization.
const Player = preload("res://features/player/player.gd")
const TerrainLayer = preload("res://features/world/tile_grid.gd")
const TerrainMap = preload("res://features/world/terrain_map.gd")
const Lighting = preload("res://features/world/lighting/world_lighting.gd")
const Story = preload("res://features/story/story_controller.gd")
@export var terrain: TerrainMap
@export var player: Player
@export var tile_grid: TerrainLayer
@export var pause_layer: CanvasLayer

func _enter_tree() -> void:
	y_sort_enabled = true
	if terrain != null and player != null:
		player.terrain = terrain
		if tile_grid != null:
			tile_grid.terrain = terrain
			tile_grid.depth_parent = self
		player.position = Vector2(terrain.spawn_cell * TerrainMap.TILE_SIZE)

func _ready() -> void:
	if terrain == null:
		return
	var lighting := Lighting.new()
	add_child(lighting)
	lighting.setup(self, terrain, player.visual if player != null else null)
	if player != null:
		var story := Story.new()
		add_child(story)
		if pause_layer != null:
			story.story_modal_open_changed.connect(pause_layer.set_story_modal_open)
		story.setup(player, terrain)
