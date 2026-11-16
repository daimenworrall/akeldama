extends Control
## Battle composition and animation only; actors occupy opposing diagonal corners.
const Actor = preload("res://features/battle/presentation/battle_actor.gd")
const Card = preload("res://features/battle/presentation/combatant_card.gd")
const Sheets = preload("res://features/dama/presentation/sheet_frames.gd")
var player_actor := Actor.new()
var enemy_actor := Actor.new()
var player_card := Card.new()
var enemy_card := Card.new()
var effect := AnimatedSprite2D.new()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for child in [player_actor, enemy_actor, player_card, enemy_card, effect]:
		add_child(child)
	effect.hide()
	resized.connect(_layout)
	_layout()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("182c36"))
	draw_rect(Rect2(0, size.y * 0.35, size.x, size.y * 0.65), Color("263c39"))
	for point in [Vector2(size.x * 0.25, size.y * 0.82), Vector2(size.x * 0.75, size.y * 0.40)]:
		draw_style_box(_platform(), Rect2(point - Vector2(155, 18), Vector2(310, 36)))

func _platform() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("3c5346")
	box.set_corner_radius_all(18)
	return box

func _layout() -> void:
	player_actor.position = Vector2(size.x * 0.25, size.y * 0.66)
	enemy_actor.position = Vector2(size.x * 0.75, size.y * 0.25)
	player_card.position = Vector2(size.x * 0.57, size.y * 0.69)
	enemy_card.position = Vector2(size.x * 0.07, size.y * 0.08)
	queue_redraw()

func render(state: RefCounted) -> void:
	if player_actor.creature != state.active(true):
		player_actor.setup(state.active(true), state.catalog, "north-east")
	if enemy_actor.creature != state.active(false):
		enemy_actor.setup(state.active(false), state.catalog, "south-west")
	player_card.display(state.active(true), state.catalog, state.player_index, state.player_party.size())
	enemy_card.display(state.active(false), state.catalog, state.enemy_index, state.enemy_party.size())
	player_actor.visible = state.active(true).health > 0
	enemy_actor.visible = state.active(false).health > 0

func present(event: Dictionary) -> void:
	var actor := player_actor if event.player else enemy_actor
	var target := enemy_actor if event.player else player_actor
	var duration: float = actor.attack(event.move.category)
	await get_tree().create_timer(duration).timeout
	if event.hit and event.move.animation != null and event.move.animation.texture != null:
		var frames := Sheets.build(event.move.animation)
		var names := frames.get_animation_names()
		if not names.is_empty():
			var clip: StringName = StringName(event.move.animation.clip) if frames.has_animation(event.move.animation.clip) else names[0]
			frames.set_animation_loop(clip, false)
			effect.sprite_frames = frames
			effect.position = target.position
			effect.rotation = 0 if event.player else PI
			effect.scale = Vector2.ONE * 2
			effect.show()
			effect.stop()
			effect.frame = 0
			effect.play(clip)
			await effect.animation_finished
			effect.hide()
	if event.hit and event.damage > 0:
		target.modulate = Color("ff8e8e")
		await get_tree().create_timer(0.15).timeout
		target.modulate = Color.WHITE
	actor.idle()
