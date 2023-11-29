extends Node2D

const width:  int = 15
const height: int = 15
const mine_count_easy:   int = 30
const mine_count_medium: int = 40
const mine_count_hard:   int = 50
const difficulty: Array = [null, mine_count_easy, mine_count_medium, mine_count_hard] # there's no level 0

var current_level: int = 2
var mines_total: int = mine_count_medium

var square_scene: Resource = load("res://Square.tscn")

var empty: bool = true
var squares: Array = []
func all_squares():
	var squares_list: Array = []
	for x in width:
		for y in height:
			squares_list.append(squares[x][y])
	return squares_list

var mines_flagged: int = 0

func _ready():
	create_blank_board()
	$Border.create_border(width, height)
	$MineCounter.position = Vector2(float(width) / 2 * Globals.square_size,
									Globals.square_size * (height + 1))
	$MineCounter/Count.set_text("%02d" % mines_total)

func reset_board(level):
	$AnimationPlayer.stop(false)
	current_level = level
	mines_total = difficulty[current_level]
	mines_flagged = 0
	update_counter()
	for square in all_squares():
		square.reset()
	empty = true
	Globals.board_locked = false

func create_blank_board():
	# create squares
	for x in width:
		squares.append([])
		for y in height:
			var square: Square = square_scene.instance()
			square.x = x
			square.y = y
			square.set_position(Vector2(x, y) * Globals.square_size)
			squares[x].append(square)
			add_child(square)
	# update neighbours
	for square in all_squares():
		square.neighbours = get_neighbours(square.x, square.y)

func get_neighbours(x, y):
	var neighbours: Array = []
	for i in range(max(0, x - 1), min(x + 2, width)):
		for j in range(max(0, y - 1), min(y + 2, height)):
			if not (i == x and j == y):
				neighbours.append(squares[i][j])
	return neighbours

var refreshes: int = 0

func create_random_board(first_square: Square):
	var max_tries: int = 100
	var solvable: bool = false
	var tries: int = 0
	while not solvable:
		reset_board(current_level)
		secure_neighbourhood(first_square)
		var mines_placed: int = 0
		while mines_placed < mines_total:
			var x = randi() % width
			var y = randi() % height
			if not squares[x][y].mined and not squares[x][y].safe:
				squares[x][y].mined = true
				mines_placed += 1
		for square in all_squares():
			square.update_mine_count()
		solvable = $Solver.solve(mines_total, squares, first_square)
		tries += 1
		if tries > max_tries:
			load_board($SafeBoards.board[current_level][first_square.x][first_square.y])
			break
	empty = false

func load_board(board: Array):
	reset_board(current_level)
	for x in width:
		for y in height:
			if board[x][y] == 1:
				squares[x][y].mined = true
	for square in all_squares():
		square.update_mine_count()
	empty = false

func secure_neighbourhood(square: Square):
	square.safe = true
	for neighbour in square.neighbours:
		neighbour.safe = true

func _input(event):
	if event is InputEventMouseButton:
		if not Globals.board_locked:
			if event.pressed:
				if event.button_index == BUTTON_LEFT:
					if Globals.active_square != null:
						Globals.active_square.hover()
						if Input.is_action_pressed("rmb"):
							for neighbour in Globals.active_square.neighbours:
								neighbour.hover()
				elif event.button_index == BUTTON_RIGHT:
					if Globals.active_square != null:
						mines_flagged += Globals.active_square.toggle_flag()
						update_counter()
			else: # button up
				if  Globals.active_square != null:
					for neighbour in Globals.active_square.neighbours:
						neighbour.unhover()
					if event.button_index == BUTTON_LEFT:
						if empty:
							create_random_board(Globals.active_square)
						if not Input.is_action_pressed("rmb"):
							Globals.active_square.uncover()
						else:
							Globals.active_square.uncover_neighbours()
						var lost: bool = check_loss()
						var won:  bool = check_win()
						if lost:
							game_lost()
						elif won:
							game_won()

func update_counter():
	$MineCounter/Count.set_text("%02d" % (mines_total - mines_flagged))

func find_loosing_square():
	for square in all_squares():
		if square.mined and not square.covered:
			return square
	return null

func check_loss():
	return find_loosing_square() != null

func check_win():
	var covered_count: int = 0
	for square in all_squares():
		if square.covered:
			covered_count += 1
	if covered_count == mines_total:
		return true
	return false

func game_lost():
	Globals.board_locked = true
	var loosing_square: Square = find_loosing_square()
	for square in all_squares():
		square.react("loss")
	loosing_square.mark_mine()

func game_won():
	Globals.board_locked = true
	for square in all_squares():
		square.react("win")
	$AnimationPlayer.play("Shine")
