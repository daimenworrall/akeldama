extends PanelContainer
signal resume_requested
signal settings_requested
signal exit_requested

func _ready() -> void:
	$Content/Resume.pressed.connect(func() -> void: resume_requested.emit())
	$Content/Settings.pressed.connect(func() -> void: settings_requested.emit())
	$Content/Exit.pressed.connect(func() -> void: exit_requested.emit())

func focus_default() -> void:
	$Content/Resume.grab_focus()
