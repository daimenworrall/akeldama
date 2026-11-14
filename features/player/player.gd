extends Node2D
## Complete one cardinal tile step before stopping or choosing another direction.
const TILE_SIZE := 32
@export_range(1.0, 512.0) var speed := 128.0
@onready var visual: Node2D = $Visual
var _destination := Vector2.ZERO
var _moving := false

func _ready() -> void:
	position = position.snapped(Vector2(TILE_SIZE, TILE_SIZE))
	_destination = position
	visual.global_position = global_position.round()

func _physics_process(delta: float) -> void:
	advance_movement(delta)

func advance_movement(delta: float) -> void:
	var remaining_distance := speed * delta
	while remaining_distance > 0.0:
		if not _moving:
			var direction := _read_direction()
			if direction == Vector2.ZERO:
				break
			_destination = position + direction * TILE_SIZE
			_moving = true
		var distance := position.distance_to(_destination)
		var travel := minf(distance, remaining_distance)
		position = position.move_toward(_destination, travel)
		remaining_distance -= travel
		if travel >= distance:
			position = _destination
			_moving = false
	visual.global_position = global_position.round()

func _read_direction() -> Vector2:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction == Vector2.ZERO:
		return Vector2.ZERO
	if absf(direction.x) >= absf(direction.y):
		return Vector2(signf(direction.x), 0)
	return Vector2(0, signf(direction.y))
