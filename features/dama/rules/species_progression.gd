extends RefCounted
## Queries content without mutating a creature or making battle decisions.
static func eligible_evolutions(species: Resource, level: int) -> PackedStringArray:
	var result := PackedStringArray()
	for evolution in species.evolutions:
		if level >= evolution.level:
			result.append(evolution.species_id)
	return result

static func learned_moves(species: Resource, level: int) -> PackedStringArray:
	var entries: Array = species.learnset.duplicate()
	entries.sort_custom(func(a: Resource, b: Resource) -> bool: return a.level < b.level)
	var result := PackedStringArray()
	for entry in entries:
		if entry.level <= level and entry.move_id not in result:
			result.append(entry.move_id)
	return result
