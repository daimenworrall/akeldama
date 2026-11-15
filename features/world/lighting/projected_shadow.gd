extends Node2D
## A flat sprite silhouette; animated sources update without owning animation.
var settings: Resource
var texture: Texture2D
var anchor := Vector2.ZERO
var source: AnimatedSprite2D

func _ready() -> void:
	z_index = -1
	set_process(source != null)

func _process(_delta: float) -> void:
	if source == null or source.sprite_frames == null:
		return
	texture = source.sprite_frames.get_frame_texture(source.animation, source.frame)
	anchor = texture.get_size() * 0.5 - source.offset
	global_position = source.global_position
	visible = source.is_visible_in_tree()
	queue_redraw()

func _draw() -> void:
	if texture == null or settings == null or not settings.shadows_enabled:
		return
	var transform: Transform2D = settings.projection(Vector2.ZERO)
	if source != null and source.flip_h:
		transform.x = -transform.x
	draw_set_transform_matrix(transform)
	draw_texture(texture, -anchor, settings.shadow_color)
