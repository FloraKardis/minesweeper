extends Node2D

class_name Square

var x: int
var y: int
var neighbours: Array = []

var covered: bool = true
var mined:   bool = false
var flagged: bool = false
var safe:    bool = false
var mine_count: int

func reset():
	covered = true
	mined   = false
	flagged = false
	safe    = false
	load_textures("square_covered", null)
	$Light.visible = false

func toggle_flag():
	if covered:
		load_textures("square_covered", "flag" if not flagged else null)
		flagged = not flagged
		return +1 if flagged else -1
	else:
		return 0

func uncover():
	if covered and not flagged:
		covered = false
		load_textures("square_uncovered", 
					  "number_" + str(mine_count) if not mined else "mine")
		if not mined and mine_count == 0:
			for neighbour in neighbours:
				neighbour.uncover()

func uncover_neighbours():
	if not covered:
		var flagged_neighbours: int = 0
		for neighbour in neighbours:
			if neighbour.flagged:
				flagged_neighbours += 1
		if flagged_neighbours == mine_count:
			for neighbour in neighbours:
				neighbour.uncover()
	unhover()

func update_mine_count():
	mine_count = 0
	for neighbour in neighbours:
		if neighbour.mined:
			mine_count += 1

func hover():
	if covered and not flagged:
		load_textures("square_uncovered", null)

func unhover():
	if covered:
		$Box.texture = load("res://Art/square_covered.png")

func react(event: String):
	if event == "loss":
		if flagged and not mined:
			load_textures("square_uncovered", "no_mine")
		if mined and not flagged:
			load_textures("square_uncovered", "mine")
	elif event == "win":
		if not covered and mine_count == 0:
			$Light.visible = true

func mark_mine():
	load_textures("square_uncovered", "marked_mine")

func _on_Area2D_mouse_entered():
	if not Globals.board_locked:
		Globals.active_square = self
		if Input.is_action_pressed("lmb"):
			hover()

func _on_Area2D_mouse_exited():
	if not Globals.board_locked:
		unhover()
		if Input.is_action_pressed("rmb"):
			for neighbour in neighbours:
				neighbour.unhover()
		if Globals.active_square == self:
			Globals.active_square = null

func load_textures(box: String, content):
	$Box.texture = load("res://Art/" + box + easter_egg_suffix + ".png")
	if content == null:
		$Content.texture = null
	else:
		$Content.texture = load("res://Art/" + content + easter_egg_suffix + ".png")

func _to_string():
	return "(" + str(x) + ", " + str(y) + ")"

# Easter egg

var using_easter_egg_assets: bool = false
var easter_egg_suffix: String = ""

func switch_assets():
	using_easter_egg_assets = not using_easter_egg_assets
	if using_easter_egg_assets:
		easter_egg_suffix = "_easter_egg"
	else:
		easter_egg_suffix = ""
	if covered:
		load_textures("square_covered", "flag" if flagged else null)
	else:
		load_textures("square_uncovered", "number_" + str(mine_count) if not mined else "mine")
		if flagged and not mined:
			load_textures("square_uncovered", "no_mine")

