@tool
extends Resource
const Member = preload("res://features/teams/data/team_member.gd")
@export var id := ""
@export var title := "New NPC team"
@export var members: Array[Member] = []
