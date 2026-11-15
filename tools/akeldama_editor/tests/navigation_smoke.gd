extends SceneTree
const Canvas = preload("res://levels/map_canvas.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	assert(ProjectSettings.get_setting("display/window/size/mode") == Window.MODE_FULLSCREEN)
	var canvas := Canvas.new()
	root.add_child(canvas)
	var original_pan := canvas.pan
	var pan_event := InputEventPanGesture.new()
	pan_event.delta = Vector2(2, -3)
	canvas._gui_input(pan_event)
	assert(canvas.pan == original_pan - Vector2(64, -96))
	var anchor := Vector2(250, 200)
	var map_point := (anchor - canvas.pan) / canvas.zoom
	var pinch := InputEventMagnifyGesture.new()
	pinch.position = anchor
	pinch.factor = 1.5
	canvas._gui_input(pinch)
	assert(is_equal_approx(canvas.zoom, 0.75))
	assert(((anchor - canvas.pan) / canvas.zoom).is_equal_approx(map_point), "Pinch moved the map under the pointer")
	pinch.factor = 100
	canvas._gui_input(pinch)
	assert(canvas.zoom == 2.0)
	pinch.factor = 0.001
	canvas._gui_input(pinch)
	assert(canvas.zoom == 0.15)
	print("PASS: fullscreen default, two-finger panning, anchored pinch zoom, zoom limits")
	quit()
