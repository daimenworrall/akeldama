extends AnimatedSprite2D
## Owns facing and animation; artwork keeps the sheet's cell-center pivot.
const SheetFrames = preload("res://features/player/player_sprite_frames.gd")
const TEXTURE = preload("res://assets/characters/player/male_player.png")
const METADATA_PATH := "res://assets/characters/player/male_player.json"
var _facing := Vector2.DOWN

func _ready() -> void:
	sprite_frames = SheetFrames.build(TEXTURE, METADATA_PATH)
	set_movement(Vector2.DOWN, false)

func set_movement(direction: Vector2, moving: bool) -> void:
	if direction != Vector2.ZERO:
		_facing = direction
	var facing := "south"
	if _facing.x > 0:
		facing = "east"
	elif _facing.x < 0:
		facing = "west"
	elif _facing.y < 0:
		facing = "north"
	flip_h = moving and facing == "west"
	var animation_direction := "east" if flip_h else facing
	var next := StringName(("walk_" if moving else "idle_") + animation_direction)
	if animation != next:
		play(next)
