extends Node2D

var border_scene: Resource = load("res://BorderPiece.tscn")

func create_border(width, height):
	# Sides
	for placing in ["n", "e", "s", "w"]:
		var type: String = "horizontal" if placing in ["n", "s"] else "vertical"
		for x in range(width if type == "horizontal" else height):
			var border: BorderPiece = border_scene.instance()
			border.set_texture_from_type(type)
			var side: int = -1 if placing in ["n", "w"] else +1
			var a = (Globals.square_size / 2) + (Globals.square_size * x)
			var dimension: int = height if type == "horizontal" else width
			var b = side * (Globals.border_width) / 2 + Globals.square_size * dimension * max(0, side)
			var position: Vector2 = Vector2(a, b) if type == "horizontal" else Vector2(b, a)
			border.set_position(position)
			add_child(border)
	# Corners
	for type in ["nw", "ne", "se", "sw"]:
		var border: BorderPiece = border_scene.instance()
		border.set_texture_from_type(type)
		var x: int = -1 if "w" in type else +1
		var y: int = -1 if "n" in type else +1
		border.set_position(Vector2(x * (Globals.border_width / 2) + Globals.square_size * width  * max(0, x),
									y * (Globals.border_width / 2) + Globals.square_size * height * max(0, y)))
		add_child(border)
