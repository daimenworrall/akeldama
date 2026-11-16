extends RefCounted
## Validates missing references, duplicate prerequisites and dependency cycles.
static func affected_by_reset(catalog: Resource, id: String) -> PackedStringArray:
	var affected := PackedStringArray()
	if catalog.quest(id) == null:
		return affected
	affected.append(id)
	var index := 0
	while index < affected.size():
		for quest in catalog.quests:
			if affected[index] in quest.prerequisites and quest.id not in affected:
				affected.append(quest.id)
		index += 1
	return affected

static func errors(catalog: Resource) -> PackedStringArray:
	var result := PackedStringArray()
	var visiting := {}
	var visited := {}
	for quest in catalog.quests:
		var seen := {}
		for id in quest.prerequisites:
			if id == quest.id:
				result.append("Quest cannot require itself: " + quest.id)
			if catalog.quest(id) == null:
				result.append("Missing prerequisite %s for %s" % [id, quest.id])
			if seen.has(id):
				result.append("Duplicate prerequisite %s for %s" % [id, quest.id])
			seen[id] = true
		_visit(quest.id, catalog, visiting, visited, result)
	return result

static func _visit(id: String, catalog: Resource, visiting: Dictionary, visited: Dictionary, result: PackedStringArray) -> void:
	if visiting.has(id):
		result.append("Quest dependency cycle includes: " + id)
		return
	if visited.has(id) or catalog.quest(id) == null:
		return
	visiting[id] = true
	for prerequisite in catalog.quest(id).prerequisites:
		_visit(prerequisite, catalog, visiting, visited, result)
	visiting.erase(id)
	visited[id] = true
