extends SceneTree
const View = preload("res://features/dialogue/conversation_view.gd")
const DialogueNode = preload("res://features/dialogue/dialogue_node.gd")
const Choice = preload("res://features/dialogue/dialogue_choice.gd")

class SampleSession extends RefCounted:
	var current: Resource
	func choices() -> Array:
		return current.choices

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for dimensions in [Vector2i(1280, 720), Vector2i(640, 360)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		root.add_child(viewport)
		var view := View.new()
		viewport.add_child(view)
		var session := SampleSession.new()
		session.current = DialogueNode.new()
		session.current.speaker = "Professor"
		session.current.text = "A long conversation line. ".repeat(100)
		for index in range(20):
			var choice := Choice.new()
			choice.text = "Response %d" % index
			if index == 10:
				choice.text += ": " + "A longer response that should wrap inside the panel. ".repeat(8)
			session.current.choices.append(choice)
		view.present(session)
		for frame in range(4):
			await process_frame
		var bounds := Rect2(Vector2.ZERO, Vector2(dimensions))
		assert(bounds.encloses(view.panel.get_global_rect()), "Dialogue grew outside the viewport")
		assert(view.choice_scroll.size.y >= 48)
		assert(view.options.size.y > view.choice_scroll.size.y, "Many choices should scroll")
		assert(view.options.size.x <= view.choice_scroll.size.x, "Long responses widened the panel")
		var last: Button = view.options.get_child(19)
		last.grab_focus()
		for frame in range(4):
			await process_frame
		assert(view.choice_scroll.scroll_vertical > 0, "Focus did not reveal the last response")
		assert(view.choice_scroll.get_global_rect().encloses(last.get_global_rect()), "Focused response is clipped")
		var down := InputEventAction.new()
		down.action = &"ui_down"
		down.pressed = true
		viewport.push_input(down)
		for frame in range(4):
			await process_frame
		assert(viewport.gui_get_focus_owner() == view.options.get_child(0), "Navigation did not wrap to first response")
		assert(view.choice_scroll.scroll_vertical == 0)
		# A new line must reset scroll and not keep deferred callbacks for old buttons.
		view.present(session)
		view.present(session)
		session.current.choices.clear()
		view.present(session)
		for frame in range(4):
			await process_frame
		assert(view.options.get_child_count() == 1 and view.options.get_child(0).text == "Close")
		assert(bounds.encloses(view.panel.get_global_rect()))
		viewport.queue_free()
		await process_frame
	print("PASS: bounded dialogue/long text, 20 scrollable choices, focus visibility, wrapped navigation, rapid line changes and Close at 1280×720 and 640×360")
	quit()
