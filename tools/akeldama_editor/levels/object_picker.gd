extends VBoxContainer
signal selected(definition: Resource)
const Definition = preload("res://features/world/objects/object_definition.gd")
var choices := OptionButton.new()
var preview := TextureRect.new()
var definitions: Array[Resource] = []

func _ready() -> void:
	var label := Label.new()
	label.text = "Object"
	add_child(label)
	for file in DirAccess.get_files_at("res://features/world/objects/definitions"):
		if file.ends_with(".tres"):
			var data = load("res://features/world/objects/definitions/" + file)
			if data is Definition:
				definitions.append(data)
				choices.add_item(data.title)
	choices.item_selected.connect(_select)
	add_child(choices)
	preview.custom_minimum_size = Vector2(200, 200)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(preview)
	var hint := Label.new()
	hint.text = "Stamp: click or drag • Erase: remove whole object\nBridges provide a walkable deck over water."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hint)
	if not definitions.is_empty():
		_select(0)

func _select(index: int) -> void:
	preview.texture = definitions[index].texture
	selected.emit(definitions[index])
