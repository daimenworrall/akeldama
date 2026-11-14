extends VBoxContainer
const DisplayService = preload("res://core/display/display_manager.gd")
@onready var display: DisplayService = get_node("/root/DisplayManager")
@onready var mode: OptionButton = $Mode/Choice
@onready var size_choice: OptionButton = $WindowSize/Choice
@onready var scaling: OptionButton = $Scaling/Choice
@onready var description: Label = $Description

func _ready() -> void:
	mode.item_selected.connect(_select_mode)
	size_choice.item_selected.connect(_select_size)
	scaling.item_selected.connect(display.set_fullscreen_scaling)
	display.display_changed.connect(_refresh)
	_refresh()

func focus_default() -> void:
	mode.grab_focus()

func _select_mode(index: int) -> void:
	display.set_fullscreen(index == 1)

func _select_size(index: int) -> void:
	display.set_windowed_size(display.BASE_SIZE * (index + 1))

func _refresh() -> void:
	var fullscreen: bool = display.is_fullscreen()
	mode.select(1 if fullscreen else 0)
	size_choice.disabled = fullscreen
	scaling.disabled = not fullscreen
	var window_size: Vector2i = display.get_windowed_size()
	var preset := -1
	for index in range(4):
		if window_size == display.BASE_SIZE * (index + 1):
			preset = index
	size_choice.select(preset)
	size_choice.text = "%d × %d (custom)" % [window_size.x, window_size.y] if preset == -1 else size_choice.get_item_text(preset)
	scaling.select(display.fullscreen_scaling)
	var explanations := [
		"Integer: crisp, equal-sized pixels. Borders may remain.",
		"Fit: fills as much as possible, preserving proportions.\nBorders remain on displays with a different aspect ratio.",
		"Stretch: fills the entire display. Proportions may change."]
	description.text = explanations[display.fullscreen_scaling]
