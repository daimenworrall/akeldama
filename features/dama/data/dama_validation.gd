extends RefCounted
## Cross-reference and numeric validation shared by authoring and future runtime checks.
const Sheets = preload("res://features/dama/presentation/sheet_frames.gd")
const STAT_FIELDS := [&"health", &"attack", &"defense", &"special_attack", &"special_defense", &"speed"]

static func errors(catalog: Resource) -> PackedStringArray:
	var result := PackedStringArray()
	for group in [catalog.types, catalog.moves, catalog.species]:
		var ids := {}
		for data in group:
			if data.id.is_empty() or not data.id.is_valid_identifier() or ids.has(data.id):
				result.append("IDs must be valid, non-empty and unique: " + data.id)
			ids[data.id] = true
			if data.title.strip_edges().is_empty():
				result.append("A name is required for " + data.id)
	for type in catalog.types:
		for id: String in type.incoming:
			var multiplier := float(type.incoming[id])
			if catalog.find_type(id) == null or not is_finite(multiplier) or multiplier < 0 or multiplier > 8:
				result.append("Invalid incoming matchup %s → %s" % [id, type.title])
	for move in catalog.moves:
		if catalog.find_type(move.type_id) == null:
			result.append("Missing type for move " + move.title)
		if move.category not in ["physical", "special", "status"] or move.power < 0 or move.power > 999:
			result.append("Invalid category or power for " + move.title)
		if (move.category == "status" and move.power != 0) or (move.category != "status" and move.power == 0):
			result.append("Damaging moves need positive power; status moves need zero power: " + move.title)
		if not is_finite(move.accuracy) or move.accuracy < 0 or move.accuracy > 100 or (move.accuracy == 0 and not move.always_hits):
			result.append("Accuracy must be above 0 and at most 100 (or use Always hits): " + move.title)
		if move.mana_points < 1 or move.mana_points > 999 or move.priority < -10 or move.priority > 10:
			result.append("Invalid mana points or priority for " + move.title)
		_art(move.animation, move.title, true, result)
	for species in catalog.species:
		_species(species, catalog, result)
	var visited := {}
	for species in catalog.species:
		_evolution_cycle(species.id, catalog, {}, visited, result)
	return result

static func _species(species: Resource, catalog: Resource, result: PackedStringArray) -> void:
	if species.types.is_empty() or species.types.size() > 2 or (species.types.size() == 2 and species.types[0] == species.types[1]):
		result.append("Choose one or two distinct types for " + species.title)
	for id in species.types:
		if catalog.find_type(id) == null:
			result.append("Unknown type %s on %s" % [id, species.title])
	if species.stats == null:
		result.append("Base stats are missing for " + species.title)
	else:
		for field in STAT_FIELDS:
			if species.stats.get(field) < 1 or species.stats.get(field) > 999:
				result.append("Base stats must be between 1 and 999: " + species.title)
	var targets := {}
	for evolution in species.evolutions:
		if catalog.find_species(evolution.species_id) == null or evolution.species_id == species.id or targets.has(evolution.species_id):
			result.append("Missing, duplicate or self evolution on " + species.title)
		if evolution.level < 2 or evolution.level > 100:
			result.append("Evolution levels must be 2–100: " + species.title)
		targets[evolution.species_id] = true
	var learned := {}
	for entry in species.learnset:
		var key := "%s:%d" % [entry.move_id, entry.level]
		if catalog.find_move(entry.move_id) == null or entry.level < 1 or entry.level > 100 or learned.has(key):
			result.append("Missing move, invalid level or duplicate learnset entry on " + species.title)
		learned[key] = true
	_art(species.art, species.title, false, result)

static func _art(art: Resource, title: String, optional: bool, result: PackedStringArray) -> void:
	if optional and art == null:
		return
	if art == null:
		result.append("Sprite sheet is missing: " + title)
		return
	if not is_finite(art.fps) or art.fps < 0 or art.fps > 120:
		result.append("Animation FPS must be 0–120: " + title)
	if optional and art.texture == null and art.metadata_path.is_empty():
		if not art.clip.is_empty():
			result.append("Animation clip has no sprite sheet: " + title)
		return
	var info := Sheets.inspect(art)
	for error in info.errors:
		result.append(title + ": " + error)
	var keys := {}
	for clip in info.clips:
		if keys.has(clip.key) or str(clip.key).is_empty():
			result.append("Duplicate/empty animation name: " + title)
		keys[clip.key] = true
	if not art.clip.is_empty() and not keys.has(art.clip):
		result.append("Unknown animation clip: " + title + " / " + art.clip)

static func _evolution_cycle(id: String, catalog: Resource, visiting: Dictionary, visited: Dictionary, result: PackedStringArray) -> void:
	if visiting.has(id):
		result.append("Evolution cycle includes " + id)
		return
	if visited.has(id) or catalog.find_species(id) == null:
		return
	visiting[id] = true
	for evolution in catalog.find_species(id).evolutions:
		_evolution_cycle(evolution.species_id, catalog, visiting, visited, result)
	visiting.erase(id)
	visited[id] = true
