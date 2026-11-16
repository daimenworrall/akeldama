extends RefCounted
## Finds original PNG/JSON pairs; metadata filenames inside JSON need not match.
static func pairs(folders: PackedStringArray) -> PackedStringArray:
	var result := PackedStringArray()
	for folder in folders:
		_scan(folder, result)
	result.sort()
	return result

static func _scan(folder: String, result: PackedStringArray) -> void:
	for file in DirAccess.get_files_at(folder):
		var path := folder.path_join(file)
		if file.get_extension().to_lower() == "png" and FileAccess.file_exists(path.get_basename() + ".json"):
			result.append(path)
	for child in DirAccess.get_directories_at(folder):
		_scan(folder.path_join(child), result)
