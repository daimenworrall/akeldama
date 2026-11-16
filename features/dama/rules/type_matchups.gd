extends RefCounted
## Dual-type defense multiplies each distinct type's incoming multiplier.
static func multiplier(catalog: Resource, attack_type: String, defense_types: PackedStringArray) -> float:
	if catalog.find_type(attack_type) == null:
		return 1.0
	var result := 1.0
	var seen := {}
	for id in defense_types:
		var type = catalog.find_type(id)
		if type != null and not seen.has(id):
			result *= float(type.incoming.get(attack_type, 1.0))
			seen[id] = true
	return result
