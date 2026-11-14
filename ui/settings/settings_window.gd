extends PanelContainer
signal back_requested

func _ready() -> void:
	$Content/Back.pressed.connect(func() -> void: back_requested.emit())

func focus_default() -> void:
	$Content/Tabs/Graphics.focus_default()
