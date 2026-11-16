extends "res://ui/content_history.gd"
const Teams = preload("res://features/teams/data/team_catalog.gd")
const Validation = preload("res://features/teams/data/team_validation.gd")
const References = preload("res://teams/team_references.gd")
const PATH := "res://features/teams/content/npc_teams.tres"
const DAMA_PATH := "res://features/dama/content/dama_catalog.tres"
var content: Resource

func open() -> void:
	catalog = ResourceLoader.load(PATH, "", ResourceLoader.CACHE_MODE_IGNORE).duplicate(true)
	refresh_content()
	dirty = false
	undo_stack.clear()
	redo_stack.clear()

func refresh_content() -> void:
	content = ResourceLoader.load(DAMA_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)

func save(path: String = PATH) -> String:
	refresh_content()
	var errors := Validation.errors(catalog, content)
	if not errors.is_empty():
		return "Save Dama content first if needed.\n" + "\n".join(errors)
	var error := ResourceSaver.save(catalog, path)
	if error != OK:
		return error_string(error)
	dirty = false
	return ""

func remove(id: String, live_level: RefCounted) -> String:
	var used := References.find(id, live_level)
	if not used.is_empty():
		return "Team is assigned to:\n" + "\n".join(used)
	var team = catalog.find_team(id)
	if team == null:
		return "Team not found."
	checkpoint()
	catalog.teams.erase(team)
	return ""
