extends VBoxContainer
## Navigates Dama content; individual forms own their editing controls.
const Document = preload("res://dama/dama_document.gd")
const Fields = preload("res://ui/content_fields.gd")
const SpeciesForm = preload("res://dama/species_form.gd")
const TypeForm = preload("res://dama/type_form.gd")
const MoveForm = preload("res://dama/move_form.gd")
const Species = preload("res://features/dama/data/species_definition.gd")
const Type = preload("res://features/dama/data/type_definition.gd")
const Move = preload("res://features/dama/data/move_definition.gd")
const KINDS := ["species", "types", "moves"]
var document := Document.new()
var tabs := TabBar.new()
var search := LineEdit.new()
var list := ItemList.new()
var form_host := VBoxContainer.new()
var form_scroll := ScrollContainer.new()
var status := Label.new()
var delete_dialog := ConfirmationDialog.new()
var selected_id := ""
var ids := PackedStringArray()
var _form_tabs := {}

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var error := document.open()
	if error != OK:
		Fields.label(self, "Could not load Dama content: " + error_string(error))
		return
	var toolbar := HFlowContainer.new()
	add_child(toolbar)
	Fields.button(toolbar, "Save Dama content", _save)
	Fields.button(toolbar, "Undo", func() -> void: document.undo(); refresh())
	Fields.button(toolbar, "Redo", func() -> void: document.redo(); refresh())
	Fields.button(toolbar, "New", _new)
	Fields.button(toolbar, "Duplicate", _duplicate)
	Fields.button(toolbar, "Delete", _request_delete)
	for title in ["Dama", "Types", "Moves"]:
		tabs.add_tab(title)
	tabs.tab_changed.connect(func(_index: int) -> void: selected_id = ""; search.text = ""; refresh())
	add_child(tabs)
	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(body)
	var browser := VBoxContainer.new()
	browser.custom_minimum_size.x = 210
	body.add_child(browser)
	search.placeholder_text = "Search by name or ID"
	search.text_changed.connect(func(_value: String) -> void: refresh())
	browser.add_child(search)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.item_selected.connect(func(index: int) -> void: selected_id = ids[index]; _show_form())
	browser.add_child(list)
	form_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	form_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	form_scroll.add_child(form_host)
	body.add_child(form_scroll)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status)
	delete_dialog.confirmed.connect(func() -> void:
		var message := document.remove(KINDS[tabs.current_tab], selected_id)
		refresh()
		if not message.is_empty():
			status.text = message)
	add_child(delete_dialog)
	refresh()

func refresh() -> void:
	if document.catalog == null:
		return
	ids.clear()
	list.clear()
	for data in document.catalog.get(KINDS[tabs.current_tab]):
		if search.text.is_empty() or search.text.to_lower() in (data.title + " " + data.id).to_lower():
			ids.append(data.id)
			list.add_item(data.title)
	if selected_id not in ids:
		selected_id = ids[0] if not ids.is_empty() else ""
	if not selected_id.is_empty():
		list.select(ids.find(selected_id))
	_show_form()

func selected() -> Resource:
	for data in document.catalog.get(KINDS[tabs.current_tab]):
		if data.id == selected_id:
			return data
	return null

func _show_form() -> void:
	for child in form_host.get_children():
		form_host.remove_child(child)
		child.queue_free()
	var data := selected()
	if data != null:
		var form: VBoxContainer
		if tabs.current_tab == 0:
			form = SpeciesForm.new()
			form.size_flags_vertical = Control.SIZE_EXPAND_FILL
		else:
			form = TypeForm.new() if tabs.current_tab == 1 else MoveForm.new()
			if tabs.current_tab == 2:
				form.size_flags_vertical = Control.SIZE_EXPAND_FILL
		form_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if tabs.current_tab in [0, 2] else ScrollContainer.SCROLL_MODE_AUTO
		form.document = document
		form.data = data
		form.edited.connect(_edited)
		form_host.add_child(form)
		if form is SpeciesForm or form is MoveForm:
			var key: String = KINDS[tabs.current_tab] + ":" + data.id
			form.tabs.current_tab = _form_tabs.get(key, 0)
			form.tabs.tab_changed.connect(func(index: int) -> void: _form_tabs[key] = index)
	_edited()

func _edited() -> void:
	status.text = "Unsaved Dama content." if document.dirty else "Dama content saved."
	var data := selected()
	if data != null:
		list.set_item_text(ids.find(data.id), data.title)

func _save() -> void:
	var error := document.save()
	status.text = "Dama content saved." if error.is_empty() else "Cannot save:\n" + error

func _new() -> void:
	document.checkpoint()
	var data: Resource
	match tabs.current_tab:
		0:
			data = Species.new()
			if not document.catalog.types.is_empty():
				data.types.append(document.catalog.types[0].id)
		1:
			data = Type.new()
		2:
			data = Move.new()
			data.animation.loop = false
			if not document.catalog.types.is_empty():
				data.type_id = document.catalog.types[0].id
	data.id = KINDS[tabs.current_tab] + "_" + Crypto.new().generate_random_bytes(4).hex_encode()
	document.catalog.get(KINDS[tabs.current_tab]).append(data)
	selected_id = data.id
	search.text = ""
	refresh()

func _duplicate() -> void:
	var data := selected()
	if data == null:
		return
	document.checkpoint()
	var copy: Resource = data.duplicate(true)
	copy.id = KINDS[tabs.current_tab] + "_" + Crypto.new().generate_random_bytes(4).hex_encode()
	copy.title += " copy"
	document.catalog.get(KINDS[tabs.current_tab]).append(copy)
	selected_id = copy.id
	search.text = ""
	refresh()

func _request_delete() -> void:
	var data := selected()
	if data == null:
		return
	var used := document.references(KINDS[tabs.current_tab], data.id)
	if not used.is_empty():
		status.text = "Cannot delete:\n" + "\n".join(used)
		return
	delete_dialog.dialog_text = "Delete %s? Undo can restore it." % data.title
	delete_dialog.popup_centered()
