@tool
extends Resource
const Definition = preload("res://features/world/objects/object_definition.gd")
@export var definition: Definition
@export var cell := Vector2i.ZERO

func world_origin() -> Vector2:
	return Vector2(cell * 64) - Vector2(32, 32) + definition.visual_offset

func visual_rect() -> Rect2:
	return Rect2(world_origin(), definition.texture.get_size())

func walkway_rect() -> Rect2:
	return Rect2(world_origin() + definition.walkway.position, definition.walkway.size)

func collision_rect() -> Rect2:
	return Rect2(world_origin() + definition.collision.position, definition.collision.size)
