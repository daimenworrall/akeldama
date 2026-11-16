extends RefCounted
## Editable map state, history, validation and resource persistence.
const Movement = preload("res://features/world/terrain_movement.gd")
const Layer = preload("res://features/world/map_layer.gd")
const Identity = preload("res://features/world/objects/entity_identity.gd")
var active_layer := 0
const Terrain = preload("res://features/world/terrain_map.gd")
var terrain: Terrain
var path := ""
var dirty := false
var undo_stack: Array[Resource] = []
var redo_stack: Array[Resource] = []

func create(width: int = 41, height: int = 31) -> void:
	terrain = Terrain.new()
	terrain.spawn_cell = Vector2i(3, 3)
	for y in range(height):
		var row := ""
		for x in range(width):
			row += "#" if x > 1 and y > 1 and x < width - 2 and y < height - 2 else "."
		terrain.corners.append(row)
	path = ""
	dirty = true
	_ensure_layers()
	_clear_history()

func open(file_path: String) -> Error:
	var resource := ResourceLoader.load(file_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if not resource is Terrain:
		return ERR_INVALID_DATA
	terrain = resource.duplicate(true)
	path = file_path
	dirty = false
	_ensure_layers()
	_clear_history()
	return OK

func save(file_path: String) -> Error:
	Identity.ensure_ids(terrain)
	if not validation_error().is_empty():
		return ERR_INVALID_DATA
	var error := ResourceSaver.save(terrain, file_path)
	if error == OK:
		path = file_path
		dirty = false
	return error

func checkpoint() -> void:
	undo_stack.append(terrain.duplicate(true))
	if undo_stack.size() > 100:
		undo_stack.pop_front()
	redo_stack.clear()

func undo() -> void:
	if undo_stack.is_empty():
		return
	redo_stack.append(terrain.duplicate(true))
	terrain = undo_stack.pop_back()
	active_layer = mini(active_layer, terrain.layers.size() - 1)
	dirty = true

func redo() -> void:
	if redo_stack.is_empty():
		return
	undo_stack.append(terrain.duplicate(true))
	terrain = redo_stack.pop_back()
	active_layer = mini(active_layer, terrain.layers.size() - 1)
	dirty = true

func paint(corner: Vector2i, grass: bool) -> void:
	if terrain.layers[active_layer].locked or not terrain.layers[active_layer].visible:
		return
	if corner.y < 0 or corner.y >= terrain.corners.size():
		return
	var row: String = terrain.corners[corner.y]
	if corner.x < 0 or corner.x >= row.length():
		return
	row[corner.x] = "#" if grass else "."
	terrain.corners[corner.y] = row
	dirty = true

func validation_error() -> String:
	if terrain == null or terrain.corners.size() < 2:
		return "Map needs at least two rows."
	var width: int = terrain.corners[0].length()
	for row: String in terrain.corners:
		if row.length() != width or width < 2:
			return "Map rows must have equal widths of at least two corners."
		if not row.replace("#", "").replace(".", "").is_empty():
			return "Map contains unknown terrain."
	for y in range(-1, terrain.corners.size()):
		for x in range(-1, width):
			if terrain.grass_mask(terrain.origin + Vector2i(x, y)) in [6, 9]:
				return "Diagonal-only grass at %s: connect or erase a corner." % (terrain.origin + Vector2i(x, y))
	var ids := {}
	for layer in terrain.layers:
		if layer.kind == Layer.Kind.OBJECTS:
			for placed in layer.objects:
				if ids.has(placed.entity_id) and not placed.entity_id.is_empty():
					return "Duplicate entity ID: " + placed.entity_id
				ids[placed.entity_id] = true
				if placed.definition == null or placed.definition.texture == null:
					return "Object is missing its definition or artwork."
				var definition = placed.definition
				if definition.provides_walkway and (not definition.walkway.has_area() or not Rect2(Vector2.ZERO, definition.texture.get_size()).encloses(definition.walkway)):
					return "Object walkway must fit inside its artwork."
			continue
		if layer.texture == null or layer.texture.get_width() % 64 != 0 or layer.texture.get_height() % 64 != 0:
			return "Tilesheets must have dimensions divisible by 64."
		if layer.kind == Layer.Kind.TERRAIN and (layer.texture.get_width() < 1536 or layer.texture.get_height() < 512):
			return "Terrain needs the connected grass/water atlas layout."
		for atlas: Vector2i in layer.cells.values():
			if atlas.x < 0 or atlas.y < 0 or atlas.x >= layer.texture.get_width() / 64 or atlas.y >= layer.texture.get_height() / 64:
				return "A painted tile is outside its layer's tilesheet."
	if not Movement.can_stand(terrain, Vector2(terrain.spawn_cell * Terrain.TILE_SIZE)):
		return "Place the spawn on safe ground or a bridge deck."
	return ""

func _clear_history() -> void:
	undo_stack.clear()
	redo_stack.clear()

func _ensure_layers() -> void:
	if terrain.layers.is_empty():
		var base := Layer.new()
		base.title = "Terrain"
		base.kind = Layer.Kind.TERRAIN
		terrain.layers.append(base)
	active_layer = 0
	if Identity.ensure_ids(terrain):
		dirty = true

func paint_tile(cell: Vector2i, atlas: Vector2i, erase: bool) -> void:
	var layer: Layer = terrain.layers[active_layer]
	if layer.locked or not layer.visible or layer.kind != Layer.Kind.TILES:
		return
	var local := cell - terrain.origin
	if local.x < 0 or local.y < 0 or local.y >= terrain.corners.size() - 1 or local.x >= terrain.corners[local.y].length() - 1:
		return
	if erase:
		layer.cells.erase(cell)
	else:
		layer.cells[cell] = atlas
	dirty = true
