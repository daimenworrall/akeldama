@tool
extends Resource
const Quest = preload("res://features/quests/quest_definition.gd")
const Conversation = preload("res://features/dialogue/conversation_definition.gd")
@export var quests: Array[Quest] = []
@export var conversations: Array[Conversation] = []

func quest(id: String) -> Quest:
	for data in quests:
		if data.id == id:
			return data
	return null

func conversation(id: String) -> Conversation:
	for data in conversations:
		if data.id == id:
			return data
	return null
