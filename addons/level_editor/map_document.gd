@tool
extends RefCounted
## Editable map state, history, validation and resource persistence.
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
	_clear_history()

func open(file_path: String) -> Error:
	var resource := ResourceLoader.load(file_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if not resource is Terrain:
		return ERR_INVALID_DATA
	terrain = resource.duplicate(true)
	path = file_path
	dirty = false
	_clear_history()
	return OK

func save(file_path: String) -> Error:
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
	dirty = true

func redo() -> void:
	if redo_stack.is_empty():
		return
	undo_stack.append(terrain.duplicate(true))
	terrain = redo_stack.pop_back()
	dirty = true

func paint(corner: Vector2i, grass: bool) -> void:
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
	if not terrain.is_walkable(Vector2(terrain.spawn_cell * Terrain.TILE_SIZE)):
		return "Place the spawn on a fully grassy tile."
	return ""

func _clear_history() -> void:
	undo_stack.clear()
	redo_stack.clear()
