extends RefCounted
## Builds named references from saved maps, with the live level taking precedence.
const Terrain = preload("res://features/world/terrain_map.gd")

static func collect(live: Resource, live_path: String) -> Dictionary:
	var result := {"ids": PackedStringArray(), "names": PackedStringArray()}
	_scan("res://features/world/maps", live, live_path, result)
	if live_path.is_empty() and live != null:
		_append(live, "Unsaved level", result)
	return result

static func _scan(folder: String, live: Resource, live_path: String, result: Dictionary) -> void:
	for file in DirAccess.get_files_at(folder):
		if not file.ends_with(".tres"):
			continue
		var path := folder.path_join(file)
		var map = live if path == live_path else ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if map is Terrain:
			_append(map, file.get_basename(), result)
	for child in DirAccess.get_directories_at(folder):
		_scan(folder.path_join(child), live, live_path, result)

static func _append(map: Resource, title: String, result: Dictionary) -> void:
	for layer in map.layers:
		for placed in layer.objects:
			if placed.entity_id.is_empty():
				continue
			result.ids.append(placed.entity_id)
			var label: String = placed.display_name if not placed.display_name.is_empty() else placed.definition.title
			result.names.append("%s / %s (%s)" % [title, label, placed.cell])
