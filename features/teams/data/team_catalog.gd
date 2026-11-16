@tool
extends Resource
const Team = preload("res://features/teams/data/team_definition.gd")
@export var teams: Array[Team] = []

func find_team(id: String) -> Team:
	for team in teams:
		if team.id == id:
			return team
	return null
