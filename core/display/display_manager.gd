extends Node
## Owns window presentation around the fixed 1280 × 720 base viewport.
signal display_changed

const BASE_SIZE := Vector2i(1280, 720)
const DEFAULT_WINDOW_SIZE := BASE_SIZE
const SETTINGS_PATH := "user://display.cfg"
var _windowed_size := DEFAULT_WINDOW_SIZE
var _windowed_position := Vector2i.ZERO
enum FullscreenScaling { INTEGER, FIT, STRETCH }
var fullscreen_scaling := FullscreenScaling.FIT
var _transitioning := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_configure_viewport()
	_restore_settings()

func _configure_viewport() -> void:
	var window := get_window()
	window.min_size = BASE_SIZE
	window.content_scale_size = BASE_SIZE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	window.size_changed.connect(_on_size_changed)

func _restore_settings() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var window := get_window()
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		fullscreen_scaling = clampi(int(config.get_value("display", "fullscreen_scaling", FullscreenScaling.FIT)), 0, 2)
		var saved_size: Variant = config.get_value("display", "window_size", DEFAULT_WINDOW_SIZE)
		if saved_size is Vector2i:
			_windowed_size = saved_size.max(BASE_SIZE)
	window.size = _fit_window_size(_windowed_size)
	_windowed_size = window.size
	var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
	window.position = usable.position + (usable.size - window.size) / 2
	_windowed_position = window.position
	set_fullscreen(bool(config.get_value("display", "fullscreen", false)))
	_apply_scaling()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.alt_pressed and event.keycode == KEY_ENTER:
			toggle_fullscreen()
			get_viewport().set_input_as_handled()

func is_fullscreen() -> bool:
	return get_window().mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]

func toggle_fullscreen() -> void:
	set_fullscreen(not is_fullscreen())

func set_fullscreen(enabled: bool) -> void:
	if _transitioning or enabled == is_fullscreen():
		return
	_transitioning = true
	var window := get_window()
	if enabled:
		if window.mode == Window.MODE_WINDOWED:
			_windowed_size = window.size
			_windowed_position = window.position
		# Borderless fullscreen is friendly to desktop overlays and Steam Deck.
		window.mode = Window.MODE_FULLSCREEN
	else:
		window.mode = Window.MODE_WINDOWED
		window.size = _windowed_size
		var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
		window.position = _windowed_position.clamp(usable.position, (usable.end - window.size).max(usable.position))
	_apply_scaling()
	# Ignore intermediate resize notifications during the OS mode transition.
	await get_tree().process_frame
	await get_tree().process_frame
	_transitioning = false
	_save_settings()
	display_changed.emit()

func set_windowed_size(size: Vector2i) -> void:
	_windowed_size = _fit_window_size(size)
	if not is_fullscreen():
		get_window().size = _windowed_size
	_save_settings()
	display_changed.emit()

func get_windowed_size() -> Vector2i:
	return _windowed_size

func _fit_window_size(size: Vector2i) -> Vector2i:
	if DisplayServer.get_name() == "headless":
		return size.max(BASE_SIZE)
	var usable := DisplayServer.screen_get_usable_rect(get_window().current_screen)
	# Leave room for window decorations.
	var available := (usable.size - Vector2i(32, 64)).max(BASE_SIZE)
	var requested := size.max(BASE_SIZE)
	var fit := minf(1.0, minf(float(available.x) / requested.x, float(available.y) / requested.y))
	return Vector2i(Vector2(requested) * fit).max(BASE_SIZE)

func set_fullscreen_scaling(value: int) -> void:
	fullscreen_scaling = clampi(value, 0, 2)
	_apply_scaling()
	_save_settings()
	display_changed.emit()

func _apply_scaling() -> void:
	var window := get_window()
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	if is_fullscreen():
		if fullscreen_scaling == FullscreenScaling.INTEGER:
			window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER
		if fullscreen_scaling == FullscreenScaling.STRETCH:
			window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE

func integer_scale_for_size(size: Vector2i) -> int:
	return maxi(1, floori(minf(float(size.x) / BASE_SIZE.x, float(size.y) / BASE_SIZE.y)))

func _on_size_changed() -> void:
	if _transitioning:
		return
	if get_window().mode == Window.MODE_WINDOWED:
		_windowed_size = get_window().size.max(BASE_SIZE)
	_save_settings()
	display_changed.emit()

func _save_settings() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var config := ConfigFile.new()
	config.set_value("display", "window_size", _windowed_size)
	config.set_value("display", "fullscreen", is_fullscreen())
	config.set_value("display", "fullscreen_scaling", fullscreen_scaling)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Could not save display settings: %s" % error_string(error))
