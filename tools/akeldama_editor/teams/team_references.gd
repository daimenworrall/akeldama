extends RefCounted
const Terrain = preload("res://features/world/terrain_map.gd")

static func find(id: String, level_document: RefCounted) -> PackedStringArray:
	var result := PackedStringArray()
	_scan("res://features/world/maps", id, level_document, result)
	if level_document != null and level_document.path.is_empty():
		_append(level_document.terrain, "Unsaved level", id, result)
	return result

static func _scan(folder: String, id: String, live: RefCounted, result: PackedStringArray) -> void:
	for file in DirAccess.get_files_at(folder):
		if not file.ends_with(".tres"):
			continue
		var path := folder.path_join(file)
		var map = live.terrain if live != null and live.path == path else ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if map is Terrain:
			_append(map, file, id, result)
	for child in DirAccess.get_directories_at(folder):
		_scan(folder.path_join(child), id, live, result)

static func _append(map: Resource, title: String, id: String, result: PackedStringArray) -> void:
	for layer in map.layers:
		for placed in layer.objects:
			if placed.team_id == id:
				result.append(title + " / " + (placed.display_name if not placed.display_name.is_empty() else placed.entity_id))
