extends RefCounted
## Initial level scaling, without individual values, effort values or natures.
static func calculate(base: Resource, level: int) -> Dictionary[StringName, int]:
	var result: Dictionary[StringName, int] = {}
	for field in [&"health", &"attack", &"defense", &"special_attack", &"special_defense", &"speed"]:
		var scaled := floori(2.0 * int(base.get(field)) * level / 100.0)
		result[field] = scaled + (level + 10 if field == &"health" else 5)
	return result
