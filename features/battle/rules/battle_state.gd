extends RefCounted
## Turn decisions and state mutation; presentation controls when actions are shown.
const Damage = preload("res://features/battle/rules/battle_damage.gd")
const Move = preload("res://features/dama/data/move_definition.gd")
var catalog: Resource
var player_party: Array = []
var enemy_party: Array = []
var player_index := 0
var enemy_index := 0
var outcome := "ongoing"
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func active(player: bool) -> RefCounted:
	return player_party[player_index] if player else enemy_party[enemy_index]

func usable_moves(creature: RefCounted) -> Array[int]:
	var result: Array[int] = []
	for index in range(creature.moves.size()):
		if creature.mana[index] > 0:
			result.append(index)
	return result

func move_for(creature: RefCounted, index: int) -> Resource:
	if index >= 0 and index < creature.moves.size():
		return catalog.find_move(creature.moves[index])
	var struggle := Move.new()
	struggle.id = "struggle"
	struggle.title = "Struggle"
	struggle.power = 40
	struggle.always_hits = true
	return struggle

func plan_turn(index: int) -> Array[Dictionary]:
	if outcome != "ongoing":
		return []
	var usable := usable_moves(active(true))
	if (not usable.is_empty() and index not in usable) or (usable.is_empty() and index != -1):
		return []
	var enemy_moves := usable_moves(active(false))
	var enemy_move := enemy_moves[rng.randi_range(0, enemy_moves.size() - 1)] if not enemy_moves.is_empty() else -1
	var player := {"actor": active(true), "player": true, "index": index}
	var enemy := {"actor": active(false), "player": false, "index": enemy_move}
	var first = move_for(player.actor, index)
	var second = move_for(enemy.actor, enemy_move)
	var player_first: bool = first.priority > second.priority
	if first.priority == second.priority:
		player_first = player.actor.stats[&"speed"] > enemy.actor.stats[&"speed"]
		if player.actor.stats[&"speed"] == enemy.actor.stats[&"speed"]:
			player_first = rng.randi_range(0, 1) == 0
	var actions: Array[Dictionary] = []
	actions.append(player if player_first else enemy)
	actions.append(enemy if player_first else player)
	return actions

func perform(intent: Dictionary) -> Dictionary:
	if outcome != "ongoing" or intent.actor.health <= 0 or intent.actor != active(intent.player):
		return {}
	var actor: RefCounted = intent.actor
	var target := active(not intent.player)
	var index := int(intent.index)
	if index < -1 or index >= actor.moves.size() or (index == -1 and not usable_moves(actor).is_empty()):
		return {}
	if index >= 0:
		if actor.mana[index] <= 0:
			return {}
		actor.mana[index] -= 1
	var move := move_for(actor, index)
	var event := Damage.resolve(actor, target, move, catalog, rng)
	event.merge({"actor": actor, "target": target, "player": intent.player, "move": move, "health_before": target.health})
	target.health = maxi(0, target.health - int(event.damage))
	event["health_after"] = target.health
	return event

func advance_fainted() -> void:
	while player_index < player_party.size() - 1 and active(true).health <= 0:
		player_index += 1
	while enemy_index < enemy_party.size() - 1 and active(false).health <= 0:
		enemy_index += 1
	if active(true).health <= 0:
		outcome = "defeat"
	elif active(false).health <= 0:
		outcome = "victory"
