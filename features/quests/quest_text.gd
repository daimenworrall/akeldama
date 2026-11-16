extends RefCounted
## Player-facing objective text shared by the journal and tracked-quest HUD.
static func objective(quest: Resource, index: int, terrain: Resource) -> String:
	if index < quest.objective_texts.size() and not quest.objective_texts[index].is_empty():
		return quest.objective_texts[index]
	if terrain != null:
		for layer in terrain.layers:
			for placed in layer.objects:
				if placed.entity_id == quest.targets[index]:
					var title: String = placed.display_name if not placed.display_name.is_empty() else placed.definition.title
					return "Interact with " + title
	return "Interact with the quest target."

static func hud(journal: RefCounted, terrain: Resource) -> String:
	var quest = journal.catalog.quest(journal.tracked_id)
	if quest == null:
		return "Quest journal: J / gamepad Y"
	var progress := int(journal.progress.get(quest.id, 0))
	var task: String = quest.completion_hint if journal.state(quest.id) == "ready" else objective(quest, progress, terrain)
	return "%s (%d/%d)\n%s\nJournal: J / Y" % [quest.title, progress, quest.targets.size(), task]
