extends SceneTree
const Main = preload("res://scenes/Main.tscn")
const Story = preload("res://features/story/story_controller.gd")
const Save = preload("res://core/save/player_save.gd")
const PATH := "user://battle_integration_test.json"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	DirAccess.remove_absolute(PATH)
	var main := Main.instantiate()
	root.add_child(main)
	await process_frame
	var story: Story
	for child in main.get_node("World").get_children():
		if child is Story:
			story = child
	story.battle.party_path = PATH
	var professor: Resource
	for layer in story.terrain.layers:
		for placed in layer.objects:
			if placed.entity_id == "demo-professor":
				professor = placed
	assert(professor.team_id == "professor_test")
	story.player.position = professor.interaction_position() + Vector2(0, 34)
	story.player._facing = Vector2.UP
	var interact := InputEventAction.new()
	interact.action = &"interact"
	interact.pressed = true
	story._unhandled_input(interact)
	var options: Array = story.session.choices()
	for index in range(options.size()):
		if options[index].action == "battle":
			assert(story.session.choose(index))
			break
	assert(story.battle.running and paused and not story.player.movement_enabled)
	var battle = story.battle
	await process_frame
	assert(battle.view.stage.player_actor.position.x < battle.view.stage.enemy_actor.position.x)
	assert(battle.view.stage.player_actor.position.y > battle.view.stage.enemy_actor.position.y)
	assert(battle.view.stage.player_actor.direction == "north-east" and battle.view.stage.enemy_actor.direction == "south-west")
	var enemy_hp: int = battle.state.active(false).health
	await battle._turn(3)
	assert(battle.state.active(false).health < enemy_hp and not battle.busy)
	assert(battle.state.active(true).mana[3] < 20)
	assert(battle.view.stage.effect.visible == false)
	await battle._turn(1)
	assert(battle.state.active(true).mana[1] == 24 and not battle.busy)
	assert(battle.view.stage.effect.visible == false)
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	Input.parse_input_event(cancel)
	Input.flush_buffered_events()
	await process_frame
	assert(battle.state.outcome == "withdrawn" and battle.view.return_button.visible)
	battle.view.return_button.pressed.emit()
	assert(not paused and not battle.running and story.player.movement_enabled)
	assert(not main.get_node("PauseLayer").overlay.visible)
	var saved := Save.load_party(battle.catalog, PATH)
	assert(saved.party[0].mana[3] < 20)
	assert(battle.heal_party() == "Your Dama are fully restored.")
	saved = Save.load_party(battle.catalog, PATH)
	assert(saved.party[0].mana[3] == 20 and saved.party[0].health == saved.party[0].stats[&"health"])
	var team = story.Teams.find_team("professor_test")
	assert(battle.launch(team, "Professor").is_empty())
	battle.state.active(false).health = 1
	await battle._turn(0)
	assert(battle.state.outcome == "victory" and battle.view.return_button.visible)
	battle.close()
	assert(not paused)
	battle.heal_party()
	assert(battle.launch(team, "Professor").is_empty())
	battle.state.active(true).health = 1
	battle.state.active(false).stats[&"speed"] = 999
	await battle._turn(0)
	assert(battle.state.outcome == "defeat" and battle.view.return_button.visible)
	battle.close()
	assert(not paused and story.player.movement_enabled)
	DirAccess.remove_absolute(PATH)
	main.queue_free()
	await process_frame
	print("PASS: professor dialogue/team, saved party, diagonal composition, animated turns, damage/MP, cancel/withdraw, victory/defeat, return/unpause and healing")
	quit()
