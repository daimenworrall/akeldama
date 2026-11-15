extends Control
## Application shell owns workspace navigation and closing the tool.
@onready var levels: Control = $Layout/Body/Levels
@onready var navigation: ItemList = $Layout/Body/Sidebar/Navigation
@onready var close_dialog: ConfirmationDialog = $DiscardChanges

func _ready() -> void:
	get_window().min_size = Vector2i(1000, 650)
	navigation.add_item("Levels")
	navigation.add_item("Entities — planned")
	navigation.add_item("Questlines — planned")
	navigation.set_item_disabled(1, true)
	navigation.set_item_disabled(2, true)
	navigation.select(0)
	close_dialog.confirmed.connect(func() -> void: get_tree().quit())

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if levels.document.dirty:
			close_dialog.popup_centered()
		else:
			get_tree().quit()
