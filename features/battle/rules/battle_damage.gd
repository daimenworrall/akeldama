extends RefCounted
const Matchups = preload("res://features/dama/rules/type_matchups.gd")

static func resolve(actor: RefCounted, target: RefCounted, move: Resource, catalog: Resource, rng: RandomNumberGenerator) -> Dictionary:
	if not move.always_hits and rng.randf() * 100 >= move.accuracy:
		return {"hit": false, "damage": 0, "multiplier": 1.0}
	var multiplier := Matchups.multiplier(catalog, move.type_id, catalog.find_species(target.species_id).types)
	if move.category == "status" or multiplier == 0:
		return {"hit": true, "damage": 0, "multiplier": multiplier}
	var physical: bool = move.category == "physical"
	var attack := int(actor.stats[&"attack" if physical else &"special_attack"])
	var defense := maxi(1, int(target.stats[&"defense" if physical else &"special_defense"]))
	var base: float = ((2.0 * actor.level / 5.0 + 2) * move.power * attack / defense) / 50.0 + 2
	var same_type := 1.5 if move.type_id in catalog.find_species(actor.species_id).types else 1.0
	var damage := maxi(1, floori(base * same_type * multiplier * rng.randf_range(0.85, 1.0)))
	return {"hit": true, "damage": mini(target.health, damage), "multiplier": multiplier}
