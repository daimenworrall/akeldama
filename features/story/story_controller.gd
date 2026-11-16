extends Node
signal story_modal_open_changed(open: bool)
## Coordinates interaction, conversation presentation and quest persistence.
const Journal = preload("res://features/quests/quest_journal.gd")
const Save = preload("res://features/quests/quest_save.gd")
const Session = preload("res://features/dialogue/conversation_session.gd")
const View = preload("res://features/dialogue/conversation_view.gd")
const Targets = preload("res://features/world/interaction/interaction_targets.gd")
const CATALOG = preload("res://features/story/content/demo_story.tres")
const JournalScreen = preload("res://features/quests/ui/quest_journal_screen.gd")
const Tracker = preload("res://features/quests/ui/quest_tracker.gd")
const Battle = preload("res://features/battle/battle_controller.gd")
const Teams = preload("res://features/teams/content/npc_teams.tres")
const Dama = preload("res://features/dama/content/dama_catalog.tres")
const Conversation = preload("res://features/dialogue/conversation_definition.gd")
const DialogueNode = preload("res://features/dialogue/dialogue_node.gd")
var journal := Journal.new()
var session := Session.new()
var view := View.new()
var journal_screen := JournalScreen.new()
var tracker := Tracker.new()
var battle := Battle.new()
var _interaction_target: Resource
var player: Node2D
var terrain: Resource
var save_path := Save.PATH

func setup(actor: Node2D, map: Resource) -> void:
	player = actor
	terrain = map
	journal.catalog = CATALOG
	Save.load_into(journal, save_path)
	session.journal = journal
	add_child(tracker)
	tracker.setup(journal, terrain)
	add_child(view)
	add_child(battle)
	battle.catalog = Dama
	battle.open_changed.connect(func(open: bool) -> void:
		player.movement_enabled = not open
		story_modal_open_changed.emit(open))
	session.action_requested.connect(_party_action)
	add_child(journal_screen)
	journal_screen.setup(journal, terrain)
	journal_screen.open_changed.connect(func(open: bool) -> void: story_modal_open_changed.emit(open))
	view.choice_selected.connect(func(index: int) -> void: session.choose(index))
	view.dismiss_requested.connect(session.close)
	session.updated.connect(func() -> void:
		view.present(session)
		story_modal_open_changed.emit(true))
	session.closed.connect(func() -> void:
		player.movement_enabled = true
		story_modal_open_changed.emit(false)
		view.close())
	journal.changed.connect(_progress_changed)

func _process(_delta: float) -> void:
	if player == null or session.current != null:
		return
	var target := Targets.nearest(terrain, player.position, player.facing())
	view.hint.text = "" if target == null else "Interact: E / Enter / A — " + (target.display_name if not target.display_name.is_empty() else target.definition.title)

func _input(event: InputEvent) -> void:
	# Consume cancel before the pause menu while a conversation is open.
	if session.current != null and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_game")):
		session.close()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if session.current == null and event.is_action_pressed("quest_journal") and not event.is_echo():
		journal_screen.open()
		get_viewport().set_input_as_handled()
		return
	if player == null or session.current != null or event.is_echo() or not event.is_action_pressed("interact"):
		return
	var target := Targets.nearest(terrain, player.position, player.facing())
	if target == null:
		return
	var conversation = CATALOG.conversation(target.conversation_id)
	if conversation == null:
		return
	journal.interact(target.entity_id)
	_interaction_target = target
	session.party_actions_available = true
	session.battle_available = Teams.find_team(target.team_id) != null
	if session.begin(conversation):
		player.movement_enabled = false
	get_viewport().set_input_as_handled()

func _progress_changed() -> void:
	var error := Save.write(journal, save_path)
	if error != OK:
		push_error("Could not save quest progress: " + error_string(error))

func _party_action(action: String) -> void:
	if action == "battle":
		var trainer: String = _interaction_target.display_name if not _interaction_target.display_name.is_empty() else _interaction_target.definition.title
		var error := battle.launch(Teams.find_team(_interaction_target.team_id), trainer)
		if not error.is_empty():
			_notice(error)
	elif action == "heal_party":
		_notice(battle.heal_party())

func _notice(text: String) -> void:
	var node := DialogueNode.new()
	node.id = "party_notice"
	node.entry = true
	node.speaker = _interaction_target.display_name if not _interaction_target.display_name.is_empty() else _interaction_target.definition.title
	node.text = text
	var conversation := Conversation.new()
	conversation.nodes.append(node)
	session.begin(conversation)
	player.movement_enabled = false
