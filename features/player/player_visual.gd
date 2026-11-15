extends AnimatedSprite2D
## Owns facing and animation; the scene anchors the artwork at its feet.
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
	# Godot angles run clockwise on screen: east, south-east, south, ...
	var directions := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]
	var sector := posmod(roundi(_facing.angle() / (PI / 4.0)), 8)
	var facing: String = directions[sector]
	var animation_direction := facing
	flip_h = false
	if moving and not sprite_frames.has_animation(StringName("walk_" + facing)):
		animation_direction = facing.replace("west", "east")
		flip_h = animation_direction != facing
	var next := StringName(("walk_" if moving else "idle_") + animation_direction)
	if animation != next:
		play(next)
