extends Control
## Terrain preview with mouse and native trackpad navigation.
signal edited
const ObjectEditing = preload("res://levels/object_editing.gd")
const Movement = preload("res://features/world/terrain_movement.gd")
var selected_object: Resource
const Preview = preload("res://levels/map_preview.gd")
const Layer = preload("res://features/world/map_layer.gd")
var selected_tile := Vector2i.ZERO
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
	Preview.draw_map(self, map, pan, zoom)
	var spawn: Vector2 = pan + (Vector2(map.spawn_cell - map.origin) + Vector2(0.5, 0.5)) * tile_size
	_draw_object_preview()
	draw_circle(spawn, 8, Color("ffe08a"))
	draw_string(ThemeDB.fallback_font, spawn + Vector2(10, 5), "Spawn", HORIZONTAL_ALIGNMENT_LEFT, -1, 14)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture:
		_zoom_at(event.position, event.factor)
	elif event is InputEventPanGesture:
		pan -= event.delta * 32.0
		queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			var direction := 1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0
			_zoom_at(event.position, pow(1.2, direction * event.factor))
		if event.button_index in [MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT] and event.pressed:
			pan.x += 32.0 * event.factor * (1.0 if event.button_index == MOUSE_BUTTON_WHEEL_LEFT else -1.0)
			queue_redraw()
		if event.button_index == MOUSE_BUTTON_LEFT:
			_painting = event.pressed and not Input.is_physical_key_pressed(KEY_SPACE)
			if _painting:
				document.checkpoint()
				_paint(event.position)
	elif event is InputEventMouseMotion:
		queue_redraw()
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE or (event.button_mask & MOUSE_BUTTON_MASK_LEFT and Input.is_physical_key_pressed(KEY_SPACE)):
			pan += event.relative
			queue_redraw()
		elif _painting and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_paint(event.position)
	accept_event()

func _zoom_at(point: Vector2, factor: float) -> void:
	if factor <= 0.0:
		return
	var old := zoom
	zoom = clampf(zoom * factor, 0.15, 2.0)
	pan = point - (point - pan) * zoom / old
	queue_redraw()

func _paint(point: Vector2) -> void:
	var local := (point - pan) / (64.0 * zoom)
	if brush == "Spawn":
		var cell: Vector2i = Vector2i(local.floor()) + document.terrain.origin
		if Movement.can_stand(document.terrain, Vector2(cell * 64)):
			document.terrain.spawn_cell = cell
			document.dirty = true
	else:
		var layer: Layer = document.terrain.layers[document.active_layer]
		if layer.kind == Layer.Kind.TERRAIN:
			if brush in ["Grass", "Water"]:
				document.paint(Vector2i(local.round()), brush == "Grass")
		elif layer.kind == Layer.Kind.OBJECTS:
			var cell: Vector2i = Vector2i(local.floor()) + document.terrain.origin
			var world_point: Vector2 = local * 64 + Vector2(document.terrain.origin * 64) - Vector2(32, 32)
			ObjectEditing.stamp(document, cell, selected_object, brush == "Erase", world_point)
		else:
			document.paint_tile(Vector2i(local.floor()) + document.terrain.origin, selected_tile, brush == "Erase")
	queue_redraw()
	edited.emit()

func _draw_object_preview() -> void:
	var layer: Layer = document.terrain.layers[document.active_layer]
	var point := get_local_mouse_position()
	if layer.kind != Layer.Kind.OBJECTS or selected_object == null or brush in ["Spawn", "Erase"] or not Rect2(Vector2.ZERO, size).has_point(point):
		return
	var cell := Vector2i(((point - pan) / (64 * zoom)).floor())
	var origin: Vector2 = Vector2(cell * 64) + selected_object.visual_offset
	var rect := Rect2(pan + origin * zoom, selected_object.texture.get_size() * zoom)
	draw_texture_rect(selected_object.texture, rect, false, Color(1, 1, 1, 0.5))
	if selected_object.provides_walkway:
		var deck := Rect2(pan + (origin + selected_object.walkway.position) * zoom, selected_object.walkway.size * zoom)
		draw_rect(deck, Color(0.3, 1, 0.6), false, 1)
