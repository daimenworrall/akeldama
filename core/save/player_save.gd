extends RefCounted
## Versioned player party storage. NPC content never defines the player's party.
const Creature = preload("res://features/creatures/creature_state.gd")
const Member = preload("res://features/teams/data/team_member.gd")
const Validation = preload("res://features/teams/data/team_validation.gd")
const PATH := "user://game_save.json"

static func load_party(catalog: Resource, path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		var starter := Creature.new()
		if catalog.find_species("cindlet") == null:
			return {"party": [], "error": "Starter species Cindlet is missing."}
		starter.configure(catalog, "cindlet", 20)
		var party: Array[RefCounted] = [starter]
		var error := write(party, path)
		return {"party": party, "error": "" if error == OK else error_string(error)}
	var parser := JSON.new()
	var parsed := parser.parse(FileAccess.get_file_as_string(path))
	var data: Variant = parser.data if parsed == OK else null
	if not data is Dictionary or data.get("version") != 1 or not data.get("party") is Array or data.party.is_empty() or data.party.size() > 6:
		return {"party": [], "error": "Player save has an invalid party. It has not been overwritten."}
	var party: Array[RefCounted] = []
	var ids := {}
	for record in data.party:
		if not record is Dictionary or not record.get("moves") is Array or not record.get("mana") is Array or not record.get("species") is String or not record.get("level") is float and not record.get("level") is int:
			return {"party": [], "error": "Player save contains an invalid Dama."}
		var member := Member.new()
		if not is_finite(float(record.level)) or (not record.get("health") is int and not record.get("health") is float) or not is_finite(float(record.health)):
			return {"party": [], "error": "Player save has invalid health or level."}
		member.species_id = record.species
		member.level = int(record.level)
		for id in record.moves:
			if not id is String:
				return {"party": [], "error": "Player save has an invalid move ID."}
			member.moves.append(id)
		if not Validation.member_errors(member, catalog).is_empty() or member.moves.is_empty() or record.mana.size() != member.moves.size() or not record.get("id") is String or record.id.is_empty() or ids.has(record.id):
			return {"party": [], "error": "Saved Dama references missing content or invalid party data."}
		var creature := Creature.new()
		creature.configure(catalog, member.species_id, member.level, member.moves)
		creature.instance_id = record.id
		creature.nickname = str(record.get("nickname", ""))
		creature.health = clampi(int(record.get("health", creature.health)), 0, creature.stats[&"health"])
		for index in range(creature.mana.size()):
			if not record.mana[index] is float and not record.mana[index] is int:
				return {"party": [], "error": "Invalid saved mana value."}
			if not is_finite(float(record.mana[index])):
				return {"party": [], "error": "Invalid saved mana value."}
			creature.mana[index] = clampi(int(record.mana[index]), 0, catalog.find_move(creature.moves[index]).mana_points)
		ids[creature.instance_id] = true
		party.append(creature)
	return {"party": party, "error": ""}

static func write(party: Array, path: String = PATH) -> Error:
	var records: Array = []
	for creature in party:
		records.append(creature.snapshot())
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"version": 1, "party": records}))
	file.close()
	return DirAccess.rename_absolute(path + ".tmp", path)
