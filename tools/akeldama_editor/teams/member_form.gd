extends VBoxContainer
signal edited
signal remove_requested
const Fields = preload("res://ui/content_fields.gd")
const Progression = preload("res://features/dama/rules/species_progression.gd")
var document: RefCounted
var member: Resource
var move_options: Array[OptionButton] = []
var auto_summary: Label

func _ready() -> void:
	_build()

func _build() -> void:
	move_options.clear()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var species_ids := PackedStringArray()
	var species_names := PackedStringArray()
	for species in document.content.species:
		species_ids.append(species.id)
		species_names.append(species.title)
	Fields.option(self, "Dama", species_ids, species_names, member.species_id, func(value: String) -> void:
		document.edit(member, &"species_id", value)
		_build()
		edited.emit())
	Fields.text(self, "Nickname (optional)", member.nickname, func(value: String) -> void:
		document.edit(member, &"nickname", value)
		edited.emit())
	Fields.number(self, "Level", member.level, 1, 100, 1, func(value: float) -> void:
		document.edit(member, &"level", int(value))
		_update_auto_summary()
		edited.emit())
	var automatic := CheckBox.new()
	automatic.text = "Automatically use latest four learned moves"
	automatic.button_pressed = member.moves.is_empty()
	automatic.toggled.connect(func(value: bool) -> void:
		var equipped := PackedStringArray()
		if not value:
			var species = document.content.find_species(member.species_id)
			if species != null:
				equipped = Progression.learned_moves(species, member.level)
				equipped = equipped.slice(maxi(0, equipped.size() - 4))
			if equipped.is_empty() and not document.content.moves.is_empty():
				equipped.append(document.content.moves[0].id)
		document.edit(member, &"moves", equipped)
		_build()
		edited.emit())
	add_child(automatic)
	auto_summary = Fields.label(self, "")
	_update_auto_summary()
	if not member.moves.is_empty():
		var ids := PackedStringArray([""])
		var names := PackedStringArray(["Empty slot"])
		for move in document.content.moves:
			ids.append(move.id)
			names.append(move.title)
		for index in range(4):
			var selected: String = member.moves[index] if index < member.moves.size() else ""
			var option := Fields.option(self, "Move %d" % (index + 1), ids, names, selected, func(_value: String) -> void: _equip())
			for item in range(option.item_count):
				option.set_item_metadata(item, ids[item] if item < ids.size() else selected)
			move_options.append(option)
	Fields.button(self, "Remove Dama", func() -> void: remove_requested.emit())
	add_child(HSeparator.new())

func _equip() -> void:
	var equipped := PackedStringArray()
	for option in move_options:
		var id: String = option.get_item_metadata(option.selected)
		if not id.is_empty():
			equipped.append(id)
	document.edit(member, &"moves", equipped)
	if equipped.is_empty():
		_build()
	edited.emit()

func _update_auto_summary() -> void:
	if not is_instance_valid(auto_summary):
		return
	auto_summary.visible = member.moves.is_empty()
	var species = document.content.find_species(member.species_id)
	if species == null:
		return
	var learned := Progression.learned_moves(species, member.level)
	learned = learned.slice(maxi(0, learned.size() - 4))
	var names := PackedStringArray()
	for id in learned:
		var move = document.content.find_move(id)
		names.append(move.title if move != null else "Missing: " + id)
	auto_summary.text = "Current moves: " + (", ".join(names) if not names.is_empty() else "None at this level")
