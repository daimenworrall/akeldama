extends "res://ui/content_history.gd"
## Catalog history, guarded deletion and validated persistence.
const Catalog = preload("res://features/dama/data/dama_catalog.gd")
const Validation = preload("res://features/dama/data/dama_validation.gd")
const TeamValidation = preload("res://features/teams/data/team_validation.gd")
const PATH := "res://features/dama/content/dama_catalog.tres"

func open(path: String = PATH) -> Error:
	var loaded = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if not loaded is Catalog:
		return ERR_INVALID_DATA
	catalog = loaded.duplicate(true)
	dirty = false
	undo_stack.clear()
	redo_stack.clear()
	return OK

func save(path: String = PATH) -> String:
	var errors := Validation.errors(catalog)
	var teams = ResourceLoader.load("res://features/teams/content/npc_teams.tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	errors.append_array(TeamValidation.errors(teams, catalog))
	if not errors.is_empty():
		return "\n".join(errors)
	var error := ResourceSaver.save(catalog, path)
	if error != OK:
		return error_string(error)
	dirty = false
	return ""

func references(kind: String, id: String) -> PackedStringArray:
	var result := PackedStringArray()
	var teams = ResourceLoader.load("res://features/teams/content/npc_teams.tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	for team in teams.teams:
		for member in team.members:
			if (kind == "species" and member.species_id == id) or (kind == "moves" and id in member.moves):
				result.append("NPC team: " + team.title)
	for species in catalog.species:
		if kind == "types" and id in species.types:
			result.append("Type used by " + species.title)
		for evolution in species.evolutions:
			if kind == "species" and evolution.species_id == id:
				result.append("Evolution target of " + species.title)
		for entry in species.learnset:
			if kind == "moves" and entry.move_id == id:
				result.append("Learned by " + species.title)
	if kind == "types":
		for move in catalog.moves:
			if move.type_id == id:
				result.append("Type used by move " + move.title)
		for type in catalog.types:
			if type.id != id and type.incoming.has(id):
				result.append("Matchup on " + type.title)
	return result

func remove(kind: String, id: String) -> String:
	var used := references(kind, id)
	if not used.is_empty():
		return "Remove these references first:\n" + "\n".join(used)
	for data in catalog.get(kind):
		if data.id == id:
			checkpoint()
			catalog.get(kind).erase(data)
			return ""
	return "Content was not found."
