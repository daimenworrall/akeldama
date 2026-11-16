extends RefCounted
const Progression = preload("res://features/dama/rules/species_progression.gd")

static func errors(teams: Resource, catalog: Resource) -> PackedStringArray:
	var result := PackedStringArray()
	var ids := {}
	for team in teams.teams:
		if not team.id.is_valid_identifier() or ids.has(team.id) or team.title.strip_edges().is_empty():
			result.append("Team needs a unique ID and a name: " + team.id)
		ids[team.id] = true
		if team.members.is_empty() or team.members.size() > 6:
			result.append("Teams need 1–6 Dama: " + team.title)
		for member in team.members:
			result.append_array(member_errors(member, catalog))
	return result

static func member_errors(member: Resource, catalog: Resource) -> PackedStringArray:
	var result := PackedStringArray()
	var species = catalog.find_species(member.species_id)
	if species == null or member.level < 1 or member.level > 100:
		result.append("Team member needs an existing species and level 1–100.")
		return result
	var moves: PackedStringArray = member.moves
	if moves.is_empty():
		moves = Progression.learned_moves(species, member.level)
		moves = moves.slice(maxi(0, moves.size() - 4))
	if moves.is_empty() or moves.size() > 4:
		result.append("Team member needs 1–4 moves: " + species.title)
	var seen := {}
	for id in moves:
		if catalog.find_move(id) == null or seen.has(id):
			result.append("Team member has missing/duplicate move: " + id)
		seen[id] = true
	return result
