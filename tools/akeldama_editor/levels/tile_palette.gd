extends Control
signal tile_selected(tile: Vector2i)
var texture: Texture2D
var selected := Vector2i.ZERO
const CELL := 28

func refresh(sheet: Texture2D) -> void:
	texture = sheet
	custom_minimum_size = Vector2(sheet.get_width() / 64, sheet.get_height() / 64) * CELL
	queue_redraw()

func _draw() -> void:
	if texture == null:
		return
	draw_texture_rect(texture, Rect2(Vector2.ZERO, custom_minimum_size), false)
	draw_rect(Rect2(Vector2(selected) * CELL, Vector2.ONE * CELL), Color.YELLOW, false, 2)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cell := Vector2i((event.position / CELL).floor())
		if cell.x >= 0 and cell.y >= 0 and cell.x < texture.get_width() / 64 and cell.y < texture.get_height() / 64:
			selected = cell
			tile_selected.emit(cell)
			queue_redraw()
