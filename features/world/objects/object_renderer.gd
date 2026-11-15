extends RefCounted
## Places whole object sprites without slicing them into atlas tiles.
static func populate(parent: Node2D, placements: Array, depth_parent: Node2D = null) -> void:
	for placed in placements:
		var sprite := Sprite2D.new()
		sprite.texture = placed.definition.texture
		sprite.centered = false
		# The parent tile layer already supplies the -32px cell-origin offset.
		sprite.position = placed.world_origin() + Vector2(32, 32)
		if placed.definition.depth_sorted and depth_parent != null:
			# Anchor the node at the prop's feet while leaving its pixels in place.
			sprite.position = placed.world_origin() + placed.definition.depth_anchor
			sprite.offset = -placed.definition.depth_anchor
			depth_parent.add_child(sprite)
		else:
			parent.add_child(sprite)
