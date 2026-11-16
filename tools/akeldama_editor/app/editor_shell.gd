extends Control
## Application shell owns workspace navigation and closing the tool.
@onready var levels: Control = $Layout/Body/Levels
@onready var navigation: ItemList = $Layout/Body/Sidebar/Navigation
@onready var close_dialog: ConfirmationDialog = $DiscardChanges
const StoryWorkspace = preload("res://story/story_workspace.gd")
const DamaWorkspace = preload("res://dama/dama_workspace.gd")
const TeamsWorkspace = preload("res://teams/teams_workspace.gd")
var story: Control
var dama: Control
var teams: Control

func _ready() -> void:
	get_window().min_size = Vector2i(1000, 650)
	navigation.add_item("Levels")
	navigation.add_item("Entities — planned")
	navigation.add_item("Story")
	navigation.add_item("Dama")
	navigation.add_item("Teams")
	navigation.set_item_disabled(1, true)
	story = StoryWorkspace.new()
	story.level_document = levels.document
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	levels.get_parent().add_child(story)
	story.hide()
	dama = DamaWorkspace.new()
	dama.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	levels.get_parent().add_child(dama)
	dama.hide()
	teams = TeamsWorkspace.new()
	teams.level_document = levels.document
	teams.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	levels.get_parent().add_child(teams)
	teams.hide()
	levels.sidebar.open_conversation_requested.connect(func(id: String) -> void:
		navigation.select(2)
		levels.hide()
		story.show()
		dama.hide()
		teams.hide()
		story.open_conversation(id))
	navigation.item_selected.connect(func(index: int) -> void:
		levels.visible = index == 0
		story.visible = index == 2
		dama.visible = index == 3
		teams.visible = index == 4
		if index == 2:
			story.refresh()
		elif index == 0:
			levels._refresh()
		elif index == 3:
			dama.refresh()
		elif index == 4:
			teams.refresh())
	navigation.select(0)
	close_dialog.confirmed.connect(func() -> void: get_tree().quit())

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if levels.document.dirty or (story != null and story.document.dirty) or (dama != null and dama.document.dirty) or (teams != null and teams.document.dirty):
			close_dialog.popup_centered()
		else:
			get_tree().quit()
