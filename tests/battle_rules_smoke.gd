extends SceneTree
const Catalog = preload("res://features/dama/content/dama_catalog.tres")
const Teams = preload("res://features/teams/content/npc_teams.tres")
const TeamValidation = preload("res://features/teams/data/team_validation.gd")
const Creature = preload("res://features/creatures/creature_state.gd")
const Battle = preload("res://features/battle/rules/battle_state.gd")
const Damage = preload("res://features/battle/rules/battle_damage.gd")
const Save = preload("res://core/save/player_save.gd")
const Actor = preload("res://features/battle/presentation/battle_actor.gd")
const PATH := "user://battle_rules_test.json"

func _initialize() -> void:
	assert(TeamValidation.errors(Teams, Catalog).is_empty())
	DirAccess.remove_absolute(PATH)
	var loaded := Save.load_party(Catalog, PATH)
	assert(loaded.error.is_empty() and loaded.party.size() == 1)
	var player: RefCounted = loaded.party[0]
	assert(player.species_id == "cindlet" and "slash" in player.moves)
	var enemy := Creature.new()
	enemy.configure(Catalog, "cindlet", 18, PackedStringArray(["tackle", "ember"]))
	var state := Battle.new()
	state.catalog = Catalog
	state.player_party = [player]
	state.enemy_party = [enemy]
	state.rng.seed = 12
	var intents := state.plan_turn(3)
	assert(intents.size() == 2 and intents[0].player)
	var before: int = enemy.health
	var mp: int = player.mana[3]
	var event := state.perform(intents[0])
	assert(event.move.id == "slash" and enemy.health < before and player.mana[3] == mp - 1)
	assert(Catalog.find_move("slash").mana_points == 20, "Battle mutated content")
	player.health -= 5
	assert(Save.write(state.player_party, PATH) == OK)
	var restored := Save.load_party(Catalog, PATH)
	assert(restored.party[0].instance_id == player.instance_id)
	assert(restored.party[0].health == player.health and restored.party[0].mana == player.mana)
	var miss = Catalog.find_move("tackle").duplicate(true)
	miss.accuracy = 0
	assert(not Damage.resolve(player, enemy, miss, Catalog, state.rng).hit)
	miss.always_hits = true
	assert(Damage.resolve(player, enemy, miss, Catalog, state.rng).hit)
	var original_stats: Dictionary = player.stats.duplicate()
	player.stats[&"attack"] = 1
	player.stats[&"special_attack"] = 500
	var physical: Dictionary = Damage.resolve(player, enemy, miss, Catalog, state.rng)
	miss.category = "special"
	assert(Damage.resolve(player, enemy, miss, Catalog, state.rng).damage > physical.damage)
	miss.category = "status"
	miss.power = 0
	assert(Damage.resolve(player, enemy, miss, Catalog, state.rng).damage == 0)
	player.stats.assign(original_stats)
	var faster_enemy: int = enemy.stats[&"speed"]
	enemy.stats[&"speed"] = 999
	state.catalog = Catalog.duplicate(true)
	state.catalog.find_move("slash").priority = 10
	assert(state.plan_turn(3)[0].player, "Priority must precede speed")
	state.catalog = Catalog
	enemy.stats[&"speed"] = faster_enemy
	player.mana.fill(0)
	assert(state.plan_turn(0).is_empty())
	assert(state.plan_turn(-1).size() == 2 and state.move_for(player, -1).id == "struggle")
	var replacement := Creature.new()
	replacement.configure(Catalog, "cindlet", 5)
	state.enemy_party.append(replacement)
	enemy.health = 0
	state.advance_fainted()
	assert(state.enemy_index == 1 and state.outcome == "ongoing")
	assert(state.perform(intents[1]).is_empty(), "Fainted/replaced actor attacked")
	replacement.health = 0
	state.advance_fainted()
	assert(state.outcome == "victory")
	var actor := Actor.new()
	actor.setup(player, Catalog, "north-east")
	assert(actor.roles.has("physical") and actor.roles.has("special"))
	actor.attack("physical")
	assert(String(actor.animation) == actor.roles.physical)
	actor.attack("status")
	assert(String(actor.animation) == actor.roles.special)
	actor.free()
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	assert(not Save.load_party(Catalog, PATH).error.is_empty())
	assert(FileAccess.get_file_as_string(PATH) == "{broken", "Corrupt save was overwritten")
	DirAccess.remove_absolute(PATH)
	print("PASS: NPC teams, independent saved party, HP/MP persistence, damage/accuracy, move exhaustion, fainting/replacements, category animation roles and corrupt-save protection")
	quit()
