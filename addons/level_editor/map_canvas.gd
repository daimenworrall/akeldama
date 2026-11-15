@tool
extends Control
## Interactive terrain preview: left-drag paints corners, middle-drag pans.
signal edited
const Atlas = preload("res://features/world/grass_water_atlas.gd")
const TEXTURE = preload("res://assets/tilesets/grass_water.png")
var document: RefCounted
var brush := "Grass"
var zoom := 0.5
var pan := Vector2(40, 40)
var _painting := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	custom_minimum_size = Vector2(500, 400)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("19232d"))
	if document == null or document.terrain == null:
		return
	var map = document.terrain
	var tile_size := 64.0 * zoom
	for y in range(map.corners.size() - 1):
		for x in range(map.corners[y].length() - 1):
			var cell := Vector2i(x, y)
			var mask: int = map.grass_mask(map.origin + cell)
			var rect := Rect2(pan + Vector2(cell) * tile_size, Vector2.ONE * tile_size)
			if not rect.intersects(Rect2(Vector2.ZERO, size)):
				continue
			draw_texture_rect_region(TEXTURE, rect, Rect2(Vector2(Atlas.BY_CORNERS[mask]) * 64, Vector2(64, 64)))
			draw_rect(rect, Color(1, 1, 1, 0.12), false)
			if mask in [6, 9]:
				draw_rect(rect, Color(1, 0.1, 0.1, 0.6))
	var spawn: Vector2 = pan + (Vector2(map.spawn_cell - map.origin) + Vector2(0.5, 0.5)) * tile_size
	draw_circle(spawn, 8, Color("ffe08a"))
	draw_string(ThemeDB.fallback_font, spawn + Vector2(10, 5), "Spawn", HORIZONTAL_ALIGNMENT_LEFT, -1, 14)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			var old := zoom
			zoom = clampf(zoom * (1.2 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.2), 0.15, 2.0)
			pan = event.position - (event.position - pan) * zoom / old
			queue_redraw()
		if event.button_index == MOUSE_BUTTON_LEFT:
			_painting = event.pressed
			if _painting:
				document.checkpoint()
				_paint(event.position)
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			pan += event.relative
			queue_redraw()
		elif _painting and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_paint(event.position)
	accept_event()

func _paint(point: Vector2) -> void:
	var local := (point - pan) / (64.0 * zoom)
	if brush == "Spawn":
		var cell: Vector2i = Vector2i(local.floor()) + document.terrain.origin
		if document.terrain.is_walkable(Vector2(cell * 64)):
			document.terrain.spawn_cell = cell
			document.dirty = true
	else:
		document.paint(Vector2i(local.round()), brush == "Grass")
	queue_redraw()
	edited.emit()
