extends Camera2D
## Smooth a floating-point target, then quantize the FINAL camera transform.
## Built-in smoothing stays disabled so it cannot reintroduce subpixel offsets.
@export var target: Node2D
@export_range(1.0, 30.0) var follow_speed := 24.0
var _smooth_position := Vector2.ZERO

func _ready() -> void:
	process_priority = 100
	process_physics_priority = 100
	position_smoothing_enabled = false
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if target:
		_smooth_position = target.global_position
		global_position = _smooth_position.round()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	_smooth_position = _smooth_position.lerp(target.global_position, 1.0 - exp(-follow_speed * delta))
	global_position = _smooth_position.round()
	force_update_scroll()
