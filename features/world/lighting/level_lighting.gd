@tool
extends Resource
## Authored level-wide tint and parallel ground-shadow projection.
@export var ambient := Color.WHITE
@export var shadows_enabled := false
@export var shadow_color := Color(0.08, 0.10, 0.16, 0.35)
@export_range(-180, 180) var shadow_angle := 45.0
@export_range(0.1, 2.0) var shadow_length := 0.6

func projection(origin: Vector2) -> Transform2D:
	var direction := Vector2.from_angle(deg_to_rad(shadow_angle)) * shadow_length
	# Negative sprite Y (height above the feet) projects along the ground.
	return Transform2D(Vector2.RIGHT, -direction, origin)
