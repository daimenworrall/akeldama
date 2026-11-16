extends RefCounted
## Pure quest state. UI, conversations and world interactions call this interface.
signal changed
const Dependencies = preload("res://features/quests/quest_dependencies.gd")
var catalog: Resource
var progress: Dictionary = {}
var completed: Dictionary = {}
var tracked_id := ""

func state(id: String) -> String:
	var definition = catalog.quest(id)
	if definition == null:
		return "missing"
	if completed.has(id):
		return "completed"
	if not progress.has(id):
		return "available" if can_start(id) else "locked"
	return "ready" if int(progress[id]) >= definition.targets.size() else "active"

func meets(id: String, required: String) -> bool:
	return required.is_empty() or state(id) == required

func can_start(id: String) -> bool:
	var definition = catalog.quest(id)
	if definition == null or progress.has(id) or completed.has(id):
		return false
	for prerequisite in definition.prerequisites:
		if catalog.quest(prerequisite) == null or not completed.has(prerequisite):
			return false
	return true

func track(id: String) -> void:
	if id == tracked_id or (not id.is_empty() and state(id) not in ["active", "ready"]):
		return
	tracked_id = id
	changed.emit()

func start(id: String) -> bool:
	if state(id) != "available":
		return false
	progress[id] = 0
	if tracked_id.is_empty():
		tracked_id = id
	changed.emit()
	return true

func interact(entity_id: String) -> void:
	var advanced := false
	for id: String in progress.keys():
		if state(id) != "active":
			continue
		var definition = catalog.quest(id)
		var index := int(progress[id])
		if definition.targets[index] == entity_id:
			progress[id] = index + 1
			advanced = true
	if advanced:
		changed.emit()

func complete(id: String) -> bool:
	if state(id) != "ready":
		return false
	completed[id] = true
	if tracked_id == id:
		tracked_id = ""
		for candidate: String in progress:
			if state(candidate) in ["active", "ready"]:
				tracked_id = candidate
				break
	changed.emit()
	return true

func snapshot() -> Dictionary:
	return {"version": 1, "progress": progress.duplicate(), "completed": completed.duplicate(), "tracked": tracked_id}

func reset(id: String) -> PackedStringArray:
	var affected := Dependencies.affected_by_reset(catalog, id)
	var modified := false
	for quest_id in affected:
		modified = progress.erase(quest_id) or modified
		modified = completed.erase(quest_id) or modified
	if tracked_id in affected:
		tracked_id = ""
		for candidate: String in progress:
			if state(candidate) in ["active", "ready"]:
				tracked_id = candidate
				break
		modified = true
	if modified:
		changed.emit()
	return affected

func restore(data: Dictionary) -> void:
	progress.clear()
	completed.clear()
	tracked_id = ""
	if data.get("version") != 1 or not data.get("progress") is Dictionary or not data.get("completed") is Dictionary:
		return
	for id: String in data.progress:
		var definition = catalog.quest(id)
		var value: Variant = data.progress[id]
		if definition == null or not (value is float or value is int):
			continue
		progress[id] = clampi(int(value), 0, definition.targets.size())
		if data.completed.get(id) == true and int(progress[id]) == definition.targets.size():
			completed[id] = true
	var saved: Variant = data.get("tracked", "")
	if saved is String and progress.has(saved) and not completed.has(saved):
		tracked_id = saved
	else:
		for id: String in progress:
			if not completed.has(id):
				tracked_id = id
				break
