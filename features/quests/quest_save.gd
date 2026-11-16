extends RefCounted
## Versioned local quest save; runtime state remains independent of storage.
const PATH := "user://quest_progress.json"

static func load_into(journal: RefCounted, path: String = PATH) -> void:
	if not FileAccess.file_exists(path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary:
		journal.restore(data)

static func write(journal: RefCounted, path: String = PATH) -> Error:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(journal.snapshot()))
	file.close()
	return DirAccess.rename_absolute(path + ".tmp", path)
