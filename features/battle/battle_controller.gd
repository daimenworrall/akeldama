extends Node
## Owns battle lifecycle and persistence, delegating rules and animation.
signal open_changed(open: bool)
const State = preload("res://features/battle/rules/battle_state.gd")
const View = preload("res://features/battle/presentation/battle_view.gd")
const Creature = preload("res://features/creatures/creature_state.gd")
const Save = preload("res://core/save/player_save.gd")
const Validation = preload("res://features/teams/data/team_validation.gd")
var catalog: Resource
var party_path := Save.PATH
var state: RefCounted
var view: CanvasLayer
var running := false
var busy := false
var _was_paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func launch(team: Resource, trainer: String) -> String:
	if running:
		return "A battle is already running."
	if team == null or team.members.is_empty() or team.members.size() > 6:
		return "This NPC has no battle team."
	for member in team.members:
		var errors := Validation.member_errors(member, catalog)
		if not errors.is_empty():
			return "\n".join(errors)
	var saved := Save.load_party(catalog, party_path)
	if not saved.error.is_empty():
		return saved.error
	state = State.new()
	state.catalog = catalog
	state.player_party = saved.party
	for member in team.members:
		var creature := Creature.new()
		creature.configure(catalog, member.species_id, member.level, member.moves)
		creature.nickname = member.nickname
		state.enemy_party.append(creature)
	state.advance_fainted()
	if state.outcome == "defeat":
		return "Your party is exhausted. Ask me to restore your Dama first."
	view = View.new()
	add_child(view)
	view.move_selected.connect(_turn)
	view.withdraw_requested.connect(_withdraw)
	view.return_requested.connect(close)
	_was_paused = get_tree().paused
	running = true
	open_changed.emit(true)
	get_tree().paused = true
	view.root.show()
	view.message.text = trainer + " challenges you. Choose a move."
	view.render(state, false)
	return ""

func _turn(index: int) -> void:
	if busy or not running or state.outcome != "ongoing":
		return
	var intents: Array = state.plan_turn(index)
	if intents.is_empty():
		return
	busy = true
	view.render(state, true)
	for intent in intents:
		var event: Dictionary = state.perform(intent)
		if event.is_empty():
			continue
		view.message.text = event.actor.title(catalog) + " used " + event.move.title + "."
		await view.stage.present(event)
		view.message.text += " " + ("It missed!" if not event.hit else ("No effect." if event.damage == 0 else "%d damage." % event.damage))
		if event.hit and event.damage > 0 and not is_equal_approx(event.multiplier, 1.0):
			view.message.text += " Super effective!" if event.multiplier > 1 else " Not very effective."
		if event.target.health <= 0:
			view.message.text += " " + event.target.title(catalog) + " fainted."
		state.advance_fainted()
		view.render(state, true)
		await get_tree().create_timer(0.65).timeout
	var error := Save.write(state.player_party, party_path)
	busy = false
	if state.outcome != "ongoing":
		view.result(state.outcome, "" if error == OK else error_string(error))
	else:
		if error != OK:
			view.message.text = "Could not save party: " + error_string(error)
		view.render(state, false)

func _withdraw() -> void:
	if busy or not running:
		return
	state.outcome = "withdrawn"
	var error := Save.write(state.player_party, party_path)
	view.result(state.outcome, "" if error == OK else error_string(error))

func close() -> void:
	if not running or busy or state.outcome == "ongoing":
		return
	view.queue_free()
	running = false
	get_tree().paused = _was_paused
	open_changed.emit(false)

func heal_party() -> String:
	var saved := Save.load_party(catalog, party_path)
	if not saved.error.is_empty():
		return saved.error
	for creature in saved.party:
		creature.restore_full(catalog)
	var error := Save.write(saved.party, party_path)
	return "Your Dama are fully restored." if error == OK else "Could not save party: " + error_string(error)

func _input(event: InputEvent) -> void:
	if running and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_game")):
		get_viewport().set_input_as_handled()
		if not busy and not event.is_echo():
			if state.outcome == "ongoing":
				_withdraw()
			else:
				close()

func _exit_tree() -> void:
	if running:
		get_tree().paused = _was_paused
