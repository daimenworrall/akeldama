extends RefCounted
## Branch evaluation and quest actions, independent of dialogue presentation.
signal updated
signal closed
var journal: RefCounted
var conversation: Resource
var current: Resource

func begin(definition: Resource) -> bool:
	current = null
	conversation = definition
	for node in definition.nodes:
		if node.entry and journal.meets(node.condition_quest, node.condition_state):
			current = node
			updated.emit()
			return true
	return false

func choices() -> Array:
	var result: Array = []
	if current != null:
		for choice in current.choices:
			if choice.action == "start" and not journal.can_start(choice.action_quest):
				continue
			if journal.meets(choice.condition_quest, choice.condition_state):
				result.append(choice)
	return result

func choose(index: int) -> bool:
	var options := choices()
	if index < 0 or index >= options.size():
		return false
	var choice = options[index]
	if not choice.next_node.is_empty() and conversation.find_node(choice.next_node) == null:
		return false
	if choice.action == "start" and not journal.start(choice.action_quest):
		return false
	if choice.action == "complete" and not journal.complete(choice.action_quest):
		return false
	if choice.next_node.is_empty():
		close()
	else:
		current = conversation.find_node(choice.next_node)
		updated.emit()
	return true

func close() -> void:
	current = null
	closed.emit()
