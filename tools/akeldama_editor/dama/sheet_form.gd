extends VBoxContainer
## Asset binding and playback controls, reusable for species and move effects.
signal edited
const Fields = preload("res://ui/content_fields.gd")
const Index = preload("res://dama/asset_index.gd")
const Sheets = preload("res://features/dama/presentation/sheet_frames.gd")
const Preview = preload("res://dama/animation_preview.gd")
var document: RefCounted
var art: Resource
var folders := PackedStringArray()
var optional := false
var preview := Preview.new()
var clips := OptionButton.new()
var info_label := Label.new()
var _keys := PackedStringArray()

func _ready() -> void:
	var paths := Index.pairs(folders)
	var ids := paths.duplicate()
	var names := PackedStringArray()
	for path in paths:
		names.append(path.get_file())
	ids.insert(0, "")
	names.insert(0, "No animation" if optional else "Choose sprite sheet…")
	var current: String = art.texture.resource_path if art.texture != null else ""
	Fields.option(self, "Sprite sheet", ids, names, current, _select_asset)
	add_child(preview)
	clips.clip_text = true
	clips.item_selected.connect(func(index: int) -> void:
		document.edit(art, &"clip", _keys[index])
		_refresh_preview()
		edited.emit())
	add_child(clips)
	Fields.number(self, "FPS override (0 = source timing)", art.fps, 0, 120, 1, func(value: float) -> void:
		document.edit(art, &"fps", value)
		_refresh_preview()
		edited.emit())
	var loop := CheckBox.new()
	loop.text = "Loop animation"
	loop.button_pressed = art.loop
	loop.toggled.connect(func(value: bool) -> void:
		document.edit(art, &"loop", value)
		_refresh_preview()
		edited.emit())
	add_child(loop)
	Fields.button(self, "Replay", preview.replay)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(info_label)
	visibility_changed.connect(func() -> void:
		if is_visible_in_tree():
			preview.replay()
		else:
			preview.sprite.pause())
	_refresh_preview()

func _select_asset(path: String) -> void:
	document.checkpoint()
	art.texture = load(path) if not path.is_empty() else null
	art.metadata_path = path.get_basename() + ".json" if not path.is_empty() else ""
	art.clip = ""
	_refresh_preview()
	edited.emit()

func _refresh_preview() -> void:
	clips.clear()
	_keys.clear()
	var info := Sheets.inspect(art)
	for clip in info.clips:
		_keys.append(clip.key)
		clips.add_item(clip.title)
		if clip.key == art.clip:
			clips.select(clips.item_count - 1)
	if _keys.is_empty() or not info.errors.is_empty():
		preview.sprite.stop()
		preview.sprite.sprite_frames = null
		info_label.text = "No effect assigned." if optional and art.texture == null else "\n".join(info.errors)
		return
	var selected: String = art.clip if art.clip in _keys else _keys[0]
	preview.show_frames(Sheets.build(art), selected)
	var count := preview.sprite.sprite_frames.get_frame_count(selected)
	info_label.text = "%d frames · %d clips · original pixels" % [count, _keys.size()]
