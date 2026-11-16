extends Control
## Displays a source frame at an integer zoom, without changing the source art.
var sprite := AnimatedSprite2D.new()

func _ready() -> void:
	custom_minimum_size = Vector2(240, 220)
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	resized.connect(_place)
	sprite.frame_changed.connect(_place)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("111b25"))
	for y in range(0, ceili(size.y), 16):
		for x in range(0, ceili(size.x), 16):
			if (x / 16 + y / 16) % 2 == 0:
				draw_rect(Rect2(x, y, 16, 16), Color("162330"))

func show_frames(frames: SpriteFrames, clip: String) -> void:
	sprite.sprite_frames = frames
	if frames.has_animation(clip):
		sprite.play(clip)
	_place()

func replay() -> void:
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(sprite.animation):
		sprite.stop()
		sprite.play()

func _place() -> void:
	sprite.position = (size * 0.5).floor()
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(sprite.animation) or sprite.sprite_frames.get_frame_count(sprite.animation) == 0:
		return
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture != null:
		var dimensions := texture.get_size()
		var zoom := maxf(1, floorf(minf((size.x - 24) / dimensions.x, (size.y - 24) / dimensions.y)))
		sprite.scale = Vector2.ONE * zoom
