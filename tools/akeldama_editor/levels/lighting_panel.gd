extends VBoxContainer
## Edits level lighting through document history; owns no rendering rules.
signal changed
var document: RefCounted
var ambient := ColorPickerButton.new()
var shadows := CheckBox.new()
var color := ColorPickerButton.new()
var angle := SpinBox.new()
var length_input := SpinBox.new()
var _refreshing := false

func _ready() -> void:
	var heading := Label.new()
	heading.text = "Level lighting"
	add_child(heading)
	ambient.edit_alpha = false
	_field("Ambient tint", ambient)
	shadows.text = "Cast ground shadows"
	add_child(shadows)
	_field("Shadow color / opacity", color)
	angle.min_value = -180
	angle.max_value = 180
	angle.step = 5
	_field("Shadow angle (degrees)", angle)
	length_input.min_value = 0.1
	length_input.max_value = 2
	length_input.step = 0.1
	_field("Shadow length", length_input)
	ambient.color_changed.connect(func(value: Color) -> void: _set_value(&"ambient", value))
	shadows.toggled.connect(func(value: bool) -> void: _set_value(&"shadows_enabled", value))
	color.color_changed.connect(func(value: Color) -> void: _set_value(&"shadow_color", value))
	angle.value_changed.connect(func(value: float) -> void: _set_value(&"shadow_angle", value))
	length_input.value_changed.connect(func(value: float) -> void: _set_value(&"shadow_length", value))
	refresh()

func _field(title: String, control: Control) -> void:
	var label := Label.new()
	label.text = title
	add_child(label)
	add_child(control)

func refresh() -> void:
	if document.terrain == null:
		return
	_refreshing = true
	var data = document.terrain.lighting
	ambient.color = data.ambient
	shadows.button_pressed = data.shadows_enabled
	color.color = data.shadow_color
	angle.value = data.shadow_angle
	length_input.value = data.shadow_length
	_refreshing = false

func _set_value(property: StringName, value: Variant) -> void:
	if _refreshing:
		return
	document.checkpoint()
	document.terrain.lighting.set(property, value)
	document.dirty = true
	changed.emit()
