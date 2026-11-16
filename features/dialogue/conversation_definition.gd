@tool
extends Resource
const DialogueNode = preload("res://features/dialogue/dialogue_node.gd")
@export var id := ""
@export var title := "New conversation"
@export var nodes: Array[DialogueNode] = []

func find_node(node_id: String) -> DialogueNode:
	for node in nodes:
		if node.id == node_id:
			return node
	return null
