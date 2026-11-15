@tool
extends Resource
## Reusable object artwork and gameplay footprint, independent of placement.
@export var title := "Object"
@export var texture: Texture2D
@export var visual_offset := Vector2.ZERO
@export var provides_walkway := false
@export var walkway := Rect2()
## Solid footprint and sorting anchor in texture pixels, before visual_offset.
@export var collision := Rect2()
@export var depth_sorted := false
@export var depth_anchor := Vector2.ZERO
@export var casts_shadow := false
