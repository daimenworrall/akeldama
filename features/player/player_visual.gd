extends Node2D
## Simple pixel-aligned player marker.
func _draw() -> void:
	draw_circle(Vector2.ZERO, 12.0, Color("c66357"), true, -1.0, false)
