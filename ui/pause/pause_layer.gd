extends CanvasLayer
@onready var overlay: Control = $Overlay
@onready var menu: PanelContainer = $Overlay/Center/PauseMenu
@onready var settings: PanelContainer = $Overlay/Center/SettingsWindow
var _was_paused := false
var _story_modal_open := false

func set_story_modal_open(value: bool) -> void:
	_story_modal_open = value

func _ready() -> void:
	menu.resume_requested.connect(close)
	menu.settings_requested.connect(_open_settings)
	menu.exit_requested.connect(func() -> void: get_tree().quit())
	settings.back_requested.connect(_show_menu)
	overlay.hide()

func _input(event: InputEvent) -> void:
	if _story_modal_open and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_game")) and not overlay.visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_game"):
		if event.is_echo():
			return
		get_viewport().set_input_as_handled()
		if not overlay.visible:
			open()
		elif settings.visible:
			_show_menu()
		else:
			close()

func open() -> void:
	_was_paused = get_tree().paused
	get_tree().paused = true
	overlay.show()
	_show_menu()

func close() -> void:
	overlay.hide()
	get_tree().paused = _was_paused

func _show_menu() -> void:
	settings.hide()
	menu.show()
	menu.focus_default()

func _open_settings() -> void:
	menu.hide()
	settings.show()
	settings.focus_default()

func _exit_tree() -> void:
	if overlay.visible:
		get_tree().paused = _was_paused
