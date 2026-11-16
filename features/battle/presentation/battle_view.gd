extends CanvasLayer
## Battle UI raises move/withdraw/return intentions; it does not calculate outcomes.
signal move_selected(index: int)
signal withdraw_requested
signal return_requested
const Stage = preload("res://features/battle/presentation/battle_stage.gd")
var stage := Stage.new()
var root := Control.new()
var message := Label.new()
var moves := GridContainer.new()
var withdraw := Button.new()
var return_button := Button.new()

func _ready() -> void:
	layer = 20
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.anchor_bottom = 0.68
	root.add_child(stage)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.anchor_top = 0.68
	root.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	margin.add_child(content)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size.y = 48
	content.add_child(message)
	var row := HBoxContainer.new()
	content.add_child(row)
	moves.columns = 2
	moves.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(moves)
	withdraw.text = "Withdraw"
	withdraw.pressed.connect(func() -> void: withdraw_requested.emit())
	row.add_child(withdraw)
	return_button.text = "Return to the professor"
	return_button.pressed.connect(func() -> void: return_requested.emit())
	content.add_child(return_button)
	return_button.hide()
	root.hide()

func render(state: RefCounted, busy: bool) -> void:
	stage.render(state)
	for child in moves.get_children():
		moves.remove_child(child)
		child.queue_free()
	var creature: RefCounted = state.active(true)
	var available: Array = state.usable_moves(creature)
	for index in range(creature.moves.size()):
		var move = state.catalog.find_move(creature.moves[index])
		_button("%s · %s\nMP %d/%d · Power %d" % [move.title, move.category, creature.mana[index], move.mana_points, move.power], index, busy or index not in available)
	if available.is_empty():
		_button("Struggle · No MP required", -1, busy)
	withdraw.disabled = busy
	if not busy and moves.get_child_count() > 0:
		for button in moves.get_children():
			if not button.disabled:
				button.grab_focus()
				break

func _button(text: String, index: int, disabled: bool) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.disabled = disabled
	button.pressed.connect(func() -> void: move_selected.emit(index))
	moves.add_child(button)

func result(outcome: String, error: String) -> void:
	message.text = {"victory": "You won the test battle!", "defeat": "Your party has fainted. Ask the professor to restore your Dama.", "withdrawn": "You withdrew from the test battle."}.get(outcome, outcome)
	if not error.is_empty():
		message.text += "\nSave failed: " + error
	moves.hide()
	withdraw.hide()
	return_button.show()
	return_button.grab_focus()
