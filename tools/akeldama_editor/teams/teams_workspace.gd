extends VBoxContainer
## NPC team authoring only. Player parties belong to game saves.
const Document = preload("res://teams/team_document.gd")
const Team = preload("res://features/teams/data/team_definition.gd")
const Member = preload("res://features/teams/data/team_member.gd")
const MemberForm = preload("res://teams/member_form.gd")
const Fields = preload("res://ui/content_fields.gd")
var document := Document.new()
var level_document: RefCounted
var list := ItemList.new()
var form := VBoxContainer.new()
var status := Label.new()
var selected_id := "professor_test"
var delete_dialog := ConfirmationDialog.new()

func _ready() -> void:
	document.open()
	var toolbar := HFlowContainer.new()
	add_child(toolbar)
	Fields.button(toolbar, "Save NPC teams", _save)
	Fields.button(toolbar, "Undo", func() -> void: document.undo(); refresh())
	Fields.button(toolbar, "Redo", func() -> void: document.redo(); refresh())
	Fields.button(toolbar, "New team", _new)
	Fields.button(toolbar, "Duplicate team", _duplicate)
	Fields.button(toolbar, "Delete team", func() -> void:
		if selected() != null:
			delete_dialog.popup_centered())
	Fields.label(self, "Assign teams to NPC instances in Levels → Inspect. Player parties are stored in the game save.")
	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(body)
	list.custom_minimum_size.x = 240
	list.item_selected.connect(func(index: int) -> void: selected_id = document.catalog.teams[index].id; _show_team())
	body.add_child(list)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(form)
	body.add_child(scroll)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status)
	delete_dialog.dialog_text = "Delete this team? Assigned teams cannot be deleted."
	delete_dialog.confirmed.connect(func() -> void:
		var error := document.remove(selected_id, level_document)
		refresh()
		if not error.is_empty():
			status.text = error)
	add_child(delete_dialog)
	refresh()

func selected() -> Resource:
	return document.catalog.find_team(selected_id)

func refresh() -> void:
	document.refresh_content()
	list.clear()
	for team in document.catalog.teams:
		list.add_item(team.title)
	if selected() == null:
		selected_id = document.catalog.teams[0].id if not document.catalog.teams.is_empty() else ""
	for index in range(document.catalog.teams.size()):
		if document.catalog.teams[index].id == selected_id:
			list.select(index)
	_show_team()

func _show_team() -> void:
	for child in form.get_children():
		form.remove_child(child)
		child.queue_free()
	var team := selected()
	if team == null:
		return
	Fields.identity(form, team.id)
	Fields.text(form, "Team name", team.title, func(value: String) -> void:
		document.edit(team, &"title", value)
		for index in range(document.catalog.teams.size()):
			list.set_item_text(index, document.catalog.teams[index].title)
		_edited())
	for member in team.members:
		var editor := MemberForm.new()
		editor.document = document
		editor.member = member
		editor.edited.connect(_edited)
		editor.remove_requested.connect(func() -> void:
			document.checkpoint()
			team.members.erase(member)
			_show_team())
		form.add_child(editor)
	var add := Fields.button(form, "Add Dama (maximum 6)", func() -> void:
		document.checkpoint()
		var member := Member.new()
		member.species_id = document.content.species[0].id
		team.members.append(member)
		_show_team())
	add.disabled = team.members.size() >= 6 or document.content.species.is_empty()
	_edited()

func _edited() -> void:
	status.text = "Unsaved NPC teams." if document.dirty else "NPC teams saved."

func _save() -> void:
	var error := document.save()
	status.text = "NPC teams saved. Save level assignments separately." if error.is_empty() else error

func _new() -> void:
	document.checkpoint()
	var team := Team.new()
	team.id = "team_" + Crypto.new().generate_random_bytes(4).hex_encode()
	document.catalog.teams.append(team)
	selected_id = team.id
	refresh()

func _duplicate() -> void:
	var team := selected()
	if team == null:
		return
	document.checkpoint()
	var copy: Resource = team.duplicate(true)
	copy.id = "team_" + Crypto.new().generate_random_bytes(4).hex_encode()
	copy.title += " copy"
	document.catalog.teams.append(copy)
	selected_id = copy.id
	refresh()
