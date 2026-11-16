extends Control
## Application shell owns workspace navigation and closing the tool.
@onready var levels: Control = $Layout/Body/Levels
@onready var navigation: ItemList = $Layout/Body/Sidebar/Navigation
@onready var close_dialog: ConfirmationDialog = $DiscardChanges
const StoryWorkspace = preload("res://story/story_workspace.gd")
var story: Control

func _ready() -> void:
	get_window().min_size = Vector2i(1000, 650)
	navigation.add_item("Levels")
	navigation.add_item("Entities — planned")
	navigation.add_item("Story")
	navigation.set_item_disabled(1, true)
	story = StoryWorkspace.new()
	story.level_document = levels.document
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	levels.get_parent().add_child(story)
	story.hide()
	levels.sidebar.open_conversation_requested.connect(func(id: String) -> void:
		navigation.select(2)
		levels.hide()
		story.show()
		story.open_conversation(id))
	navigation.item_selected.connect(func(index: int) -> void:
		levels.visible = index == 0
		story.visible = index == 2
		if index == 2:
			story.refresh()
		else:
			levels._refresh())
	navigation.select(0)
	close_dialog.confirmed.connect(func() -> void: get_tree().quit())

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if levels.document.dirty or (story != null and story.document.dirty):
			close_dialog.popup_centered()
		else:
			get_tree().quit()
