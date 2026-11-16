extends RefCounted
## An owned creature's mutable HP and move MP, independent of authored templates.
const Stats = preload("res://features/creatures/creature_stats.gd")
const Progression = preload("res://features/dama/rules/species_progression.gd")
var instance_id := ""
var species_id := ""
var nickname := ""
var level := 1
var stats: Dictionary[StringName, int] = {}
var health := 0
var moves := PackedStringArray()
var mana: Array[int] = []

func title(catalog: Resource) -> String:
	return nickname if not nickname.is_empty() else catalog.find_species(species_id).title

func configure(catalog: Resource, species: String, at_level: int, equipped := PackedStringArray()) -> void:
	instance_id = Crypto.new().generate_random_bytes(16).hex_encode()
	species_id = species
	level = at_level
	stats = Stats.calculate(catalog.find_species(species).stats, level)
	moves = equipped.duplicate()
	if moves.is_empty():
		moves = Progression.learned_moves(catalog.find_species(species), level)
		moves = moves.slice(maxi(0, moves.size() - 4))
	restore_full(catalog)

func restore_full(catalog: Resource) -> void:
	health = stats[&"health"]
	mana.clear()
	for id in moves:
		mana.append(catalog.find_move(id).mana_points)

func snapshot() -> Dictionary:
	return {"id": instance_id, "species": species_id, "nickname": nickname, "level": level, "health": health, "moves": Array(moves), "mana": mana.duplicate()}
