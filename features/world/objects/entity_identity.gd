extends RefCounted
## IDs are generated only for new/migrated instances, never on resource load.
static func create() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()

static func ensure_ids(terrain: Resource) -> bool:
	var changed := false
	for layer in terrain.layers:
		for placed in layer.objects:
			if placed.entity_id.is_empty():
				placed.entity_id = create()
				changed = true
	return changed
