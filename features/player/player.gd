extends Node2D
## Continuous eight-direction movement; terrain owns foot-area collision rules.
const PlayerVisual = preload("res://features/player/player_visual.gd")
const TerrainMap = preload("res://features/world/terrain_map.gd")
const TerrainMovement = preload("res://features/world/terrain_movement.gd")
@export var terrain: TerrainMap
@export_range(1.0, 512.0) var speed := 192.0
@onready var visual: PlayerVisual = $Visual
var _facing := Vector2.DOWN

func _ready() -> void:
	visual.global_position = global_position.round()

func _physics_process(delta: float) -> void:
	advance_movement(delta)

func advance_movement(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		_facing = direction
	var start := position
	position = TerrainMovement.move(terrain, position, direction * speed * delta)
	visual.global_position = global_position.round()
	visual.set_movement(_facing, not position.is_equal_approx(start))
