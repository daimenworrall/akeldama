extends RefCounted
## Converts the supplied character-sheet metadata into Godot animations.

static func build(texture: Texture2D, metadata_path: String) -> SpriteFrames:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
	var sheet: Dictionary = data["spritesheet"]
	var cell := Vector2(sheet["cell_size"]["width"], sheet["cell_size"]["height"])
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for row: Dictionary in sheet["rows"]:
		if row["type"] == "rotations":
			for column in range(int(row["frame_count"])):
				var animation := StringName("idle_" + str(row["directions"][column]))
				frames.add_animation(animation)
				frames.add_frame(animation, _frame(texture, cell, column, int(row["row"])))
		elif row["type"] == "animation" and row["animation"] in ["Walk", "Walking"]:
			var animation := StringName("walk_" + str(row["direction"]))
			frames.add_animation(animation)
			frames.set_animation_speed(animation, 6.0)
			frames.set_animation_loop(animation, true)
			for column in range(int(row["frame_count"])):
				frames.add_frame(animation, _frame(texture, cell, column, int(row["row"])))
	return frames

static func _frame(texture: Texture2D, cell: Vector2, column: int, row: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(Vector2(column, row) * cell, cell)
	return atlas
