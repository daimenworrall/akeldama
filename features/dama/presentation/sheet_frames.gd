extends RefCounted
## Reads PixelLab character rows and Aseprite-style VFX frame arrays.
static func inspect(art: Resource) -> Dictionary:
	var result := {"clips": [], "errors": PackedStringArray()}
	if art == null or art.texture == null:
		result.errors.append("Choose a sprite sheet.")
		return result
	if not FileAccess.file_exists(art.metadata_path):
		result.errors.append("Sprite JSON is missing: " + art.metadata_path)
		return result
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(art.metadata_path))
	if not data is Dictionary:
		result.errors.append("Sprite JSON must be an object.")
		return result
	if data.get("spritesheet") is Dictionary:
		_character(data.spritesheet, art.texture.get_size(), result)
	elif data.get("frames") is Array:
		_effect(data, art.texture.get_size(), result)
	else:
		result.errors.append("Unsupported sprite JSON layout.")
	if result.clips.is_empty() and result.errors.is_empty():
		result.errors.append("The sheet contains no animations.")
	return result

static func _character(sheet: Dictionary, size: Vector2, result: Dictionary) -> void:
	var cell: Variant = sheet.get("cell_size", {})
	var rows: Variant = sheet.get("rows", [])
	if not cell is Dictionary or not rows is Array:
		result.errors.append("Character sheet needs cell_size and rows.")
		return
	var width := int(cell.get("width", 0))
	var height := int(cell.get("height", 0))
	if width <= 0 or height <= 0:
		result.errors.append("Character cells must have positive dimensions.")
		return
	for row in rows:
		if not row is Dictionary:
			result.errors.append("Invalid character row.")
			continue
		var y := int(row.get("row", -1))
		var count := int(row.get("frame_count", 0))
		if count <= 0 or y < 0 or count * width > size.x or (y + 1) * height > size.y:
			result.errors.append("Character row extends outside the texture.")
			continue
		if row.get("type") == "rotations":
			var directions: Variant = row.get("directions", [])
			if not directions is Array or directions.size() != count:
				result.errors.append("Rotation directions do not match the frame count.")
				continue
			for index in range(count):
				result.clips.append({"key": "idle_" + str(directions[index]), "role": "idle", "direction": str(directions[index]), "title": "Idle / " + str(directions[index]), "rects": [Rect2(index * width, y * height, width, height)], "durations": [], "timed": false})
		else:
			var rects: Array[Rect2] = []
			for index in range(count):
				rects.append(Rect2(index * width, y * height, width, height))
			var direction := str(row.get("direction", "south"))
			var title := str(row.get("animation", "Animation"))
			if title.length() > 48:
				title = title.left(45) + "…"
			result.clips.append({"key": "row_%d_%s" % [y, direction], "role": str(row.get("animation", "")).strip_edges().to_lower(), "direction": direction, "title": "%s / %s" % [title, direction], "rects": rects, "durations": [], "timed": false})

static func _effect(data: Dictionary, size: Vector2, result: Dictionary) -> void:
	var rects: Array[Rect2] = []
	var durations: Array[float] = []
	for frame in data.frames:
		if not frame is Dictionary or not frame.get("frame") is Dictionary or frame.get("rotated", false) or frame.get("trimmed", false):
			result.errors.append("Effect frames must contain unrotated, untrimmed rectangles.")
			return
		var box: Dictionary = frame.frame
		var rect := Rect2(float(box.get("x", -1)), float(box.get("y", -1)), float(box.get("w", 0)), float(box.get("h", 0)))
		var duration := float(frame.get("duration", 0))
		if not rect.has_area() or not Rect2(Vector2.ZERO, size).encloses(rect) or not is_finite(duration) or duration <= 0:
			result.errors.append("Effect rectangle or frame duration is invalid.")
			return
		rects.append(rect)
		durations.append(duration)
	if rects.is_empty():
		return
	var meta: Variant = data.get("meta", {})
	var tags: Variant = meta.get("frameTags", []) if meta is Dictionary else []
	if not tags is Array:
		result.errors.append("Effect frameTags must be an array.")
		return
	if tags.is_empty():
		tags = [{"name": "effect", "from": 0, "to": rects.size() - 1}]
	for tag in tags:
		if not tag is Dictionary:
			result.errors.append("Invalid effect animation tag.")
			continue
		var first := int(tag.get("from", -1))
		var last := int(tag.get("to", -1))
		if first < 0 or last < first or last >= rects.size() or tag.get("direction", "forward") not in ["forward", "reverse"]:
			result.errors.append("Effect animation range/direction is invalid.")
			continue
		var selected: Array = rects.slice(first, last + 1)
		var times: Array = durations.slice(first, last + 1)
		if tag.get("direction", "forward") == "reverse":
			selected.reverse()
			times.reverse()
		var key := str(tag.get("name", "effect"))
		result.clips.append({"key": key, "title": key, "rects": selected, "durations": times, "timed": true})

static func build(art: Resource) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var info := inspect(art)
	if not info.errors.is_empty():
		return frames
	for clip in info.clips:
		var key := StringName(clip.key)
		frames.add_animation(key)
		frames.set_animation_loop(key, art.loop)
		var timing: bool = clip.timed and art.fps == 0
		frames.set_animation_speed(key, 1000 if timing else (art.fps if art.fps > 0 else 12))
		for index in range(clip.rects.size()):
			var texture := AtlasTexture.new()
			texture.atlas = art.texture
			texture.region = clip.rects[index]
			frames.add_frame(key, texture, clip.durations[index] if timing else 1.0)
	return frames
