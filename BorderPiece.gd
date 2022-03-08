extends Sprite

class_name BorderPiece

func set_texture_from_type(type: String):
	assert(type in ["nw", "ne", "se", "sw", "vertical", "horizontal"])
	texture = load("res://Art/border_corner_nw.png")
	if type == "ne":
		rotation_degrees = 90
	if type == "se":
		rotation_degrees = 180
	if type == "sw":
		rotation_degrees = 270
	if type == "horizontal":
		texture = load("res://Art/border_horizontal.png")
	if type == "vertical":
		texture = load("res://Art/border_vertical.png")
	
