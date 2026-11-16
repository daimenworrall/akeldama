@tool
extends Resource
## Presentation binding; source PNG/JSON are kept intact.
@export var texture: Texture2D
@export_file("*.json") var metadata_path := ""
@export var clip := ""
## Zero preserves source timing (or 12 FPS for untimed character rows).
@export var fps := 0.0
@export var loop := true
