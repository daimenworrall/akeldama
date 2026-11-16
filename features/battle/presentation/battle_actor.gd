extends AnimatedSprite2D
## Selects named attack roles while retaining the supplied directional perspective.
const Sheets = preload("res://features/dama/presentation/sheet_frames.gd")
var creature: RefCounted
var catalog: Resource
var direction := "north-east"
var roles := {}

func setup(state: RefCounted, content: Resource, facing: String) -> void:
	creature = state
	catalog = content
	direction = facing
	var art = catalog.find_species(creature.species_id).art
	sprite_frames = Sheets.build(art)
	roles.clear()
	for clip in Sheets.inspect(art).clips:
		if clip.get("direction") == direction:
			roles[clip.get("role", "")] = clip.key
	for key in sprite_frames.get_animation_names():
		sprite_frames.set_animation_loop(key, false)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = Vector2.ONE * 3
	idle()

func idle() -> void:
	var key := StringName("idle_" + direction)
	if sprite_frames.has_animation(key):
		play(key)

func attack(category: String) -> float:
	var role := "physical" if category == "physical" else "special"
	if not roles.has(role):
		idle()
		return 0.25
	var key := StringName(roles[role])
	frame = 0
	play(key)
	var duration := 0.0
	for index in range(sprite_frames.get_frame_count(key)):
		duration += sprite_frames.get_frame_duration(key, index) / sprite_frames.get_animation_speed(key)
	return duration
