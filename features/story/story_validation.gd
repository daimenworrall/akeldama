extends RefCounted
## Content validation shared by the editor and automated checks.
const Dependencies = preload("res://features/quests/quest_dependencies.gd")
const STATES := ["", "locked", "available", "active", "ready", "completed"]

static func errors(catalog: Resource, entity_ids: PackedStringArray) -> PackedStringArray:
	var result := PackedStringArray()
	result.append_array(Dependencies.errors(catalog))
	var quest_ids := {}
	for quest in catalog.quests:
		if quest.id.is_empty() or quest_ids.has(quest.id):
			result.append("Quest IDs must be non-empty and unique: " + quest.id)
		quest_ids[quest.id] = true
		if quest.targets.is_empty():
			result.append("Quest has no interaction objectives: " + quest.id)
		for target in quest.targets:
			if target not in entity_ids:
				result.append("Missing entity %s in quest %s" % [target, quest.id])
	var conversation_ids := {}
	for conversation in catalog.conversations:
		if conversation.id.is_empty() or conversation_ids.has(conversation.id):
			result.append("Conversation IDs must be non-empty and unique: " + conversation.id)
		conversation_ids[conversation.id] = true
		var node_ids := {}
		var entries: Array[String] = []
		for node in conversation.nodes:
			if node.id.is_empty() or node_ids.has(node.id):
				result.append("Node IDs must be non-empty and unique in " + conversation.id)
			node_ids[node.id] = true
			if node.entry:
				entries.append(node.id)
			_condition(catalog, node, result)
			for choice in node.choices:
				_condition(catalog, choice, result)
				if not choice.next_node.is_empty() and conversation.find_node(choice.next_node) == null:
					result.append("Missing dialogue destination: " + choice.next_node)
				if choice.action not in ["", "start", "complete"]:
					result.append("Unknown dialogue action: " + choice.action)
				if not choice.action.is_empty() and catalog.quest(choice.action_quest) == null:
					result.append("Action references missing quest: " + choice.action_quest)
		if entries.is_empty():
			result.append("Conversation needs an entry node: " + conversation.id)
		var reached := {}
		var pending := entries.duplicate()
		while not pending.is_empty():
			var id: String = pending.pop_back()
			if reached.has(id):
				continue
			reached[id] = true
			var node = conversation.find_node(id)
			if node != null:
				for choice in node.choices:
					if not choice.next_node.is_empty():
						pending.append(choice.next_node)
		for id: String in node_ids:
			if not reached.has(id):
				result.append("Unreachable dialogue node: " + id)
	return result

static func _condition(catalog: Resource, data: Resource, result: PackedStringArray) -> void:
	if data.condition_state not in STATES:
		result.append("Unknown quest condition: " + data.condition_state)
	if not data.condition_state.is_empty() and catalog.quest(data.condition_quest) == null:
		result.append("Condition references missing quest: " + data.condition_quest)
