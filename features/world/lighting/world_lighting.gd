extends Node2D
## Builds level shadows independently of movement, object sorting and UI.
const Shadow = preload("res://features/world/lighting/projected_shadow.gd")
const Layer = preload("res://features/world/map_layer.gd")

func setup(world: Node2D, terrain: Resource, player_visual: AnimatedSprite2D) -> void:
	var settings = terrain.lighting
	world.modulate = settings.ambient
	if not settings.shadows_enabled:
		return
	for layer in terrain.layers:
		if layer.kind != Layer.Kind.OBJECTS or not layer.visible:
			continue
		for placed in layer.objects:
			if not placed.definition.casts_shadow:
				continue
			var shadow := Shadow.new()
			shadow.settings = settings
			shadow.texture = placed.definition.texture
			shadow.anchor = placed.definition.depth_anchor
			shadow.position = placed.world_origin() + shadow.anchor
			shadow.modulate.a = layer.opacity
			add_child(shadow)
	if player_visual != null:
		var shadow := Shadow.new()
		shadow.settings = settings
		shadow.source = player_visual
		add_child(shadow)
