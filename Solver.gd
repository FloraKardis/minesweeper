extends Control

class PossiblyMinedSquaresList:
	var list: Array
	var mine_count: int
	func _init(list, mine_count):
		self.list = list
		self.mine_count = mine_count

class SolverSquare:
	var x: int
	var y: int
	var covered: bool = true
	var flagged: bool = false
	var mined: bool
	var mine_count: int
	var flagged_count: int = 0
	var neighbours_all: Array
	var neighbours_covered_unflagged: Array
	func _init(square: Square):
		x = square.x
		y = square.y
		mined = square.mined
		mine_count = square.mine_count
	func remaining_mines():
		return mine_count - flagged_count

var lists: Array = []
var mines_total: int 
var mines_flagged: int = 0
var squares: Array = []
var interesting_squares: Array = []

var prepared = false

func solve(mines_total: int, squares: Array, clicked_square: Square):
	prepare(mines_total,squares, clicked_square)
	var making_progress: bool = true
	while making_progress:
		making_progress = try_progressing()
	var time_stop: int = OS.get_ticks_msec()
	return is_solved()

func is_solved():
	return mines_total == mines_flagged

func prepare(mines_total: int, squares: Array, clicked_square: Square):
	self.mines_total = mines_total
	self.mines_flagged = 0
	self.squares             = []
	self.interesting_squares = []
	# copy board
	for x in len(squares):
		self.squares.append([])
		for y in len(squares[0]):
			self.squares[x].append(SolverSquare.new(squares[x][y]))
	assert(len(self.squares) == len(squares))
	# connect neighbours
	for x in len(self.squares):
		for square in self.squares[x]:
			square.neighbours_all = get_neighbours(square.x, square.y)
			square.neighbours_covered_unflagged = square.neighbours_all.duplicate()
	# mark clicked
	var clicked: SolverSquare = self.squares[clicked_square.x][clicked_square.y]
	uncover(clicked)
	interesting_squares.append(clicked)

func get_neighbours(x, y):
	var neighbours: Array = []
	for i in range(max(0, x - 1), min(x + 2, len(squares))):
		for j in range(max(0, y - 1), min(y + 2, len(squares[0]))):
			if not (i == x and j == y):
				neighbours.append(squares[i][j])
	return neighbours

func simple_uncover(square: Square):
	if square.covered and not square.flagged:
		square.covered = false
		square.load_textures("square_uncovered", 
							 "number_" + str(square.mine_count) if not square.mined else "mine")

func try_progressing() -> bool:
	var making_progress: bool = update_squares()
	if not making_progress:
		making_progress = update_mine_count()
	return making_progress

func update_squares() -> bool:
	for square in interesting_squares.duplicate():
		# check if interesting:
		if square.neighbours_covered_unflagged.empty():
			interesting_squares.erase(square)
			return true
		# remaining_mines == 0
		if square.remaining_mines() == 0:
			interesting_squares.erase(square)
			for neighbour in square.neighbours_covered_unflagged.duplicate():
				uncover(neighbour)
			return true
		# remaining_mines == unflagged squares
		if square.remaining_mines() == len(square.neighbours_covered_unflagged):
			interesting_squares.erase(square)
			for neighbour in square.neighbours_covered_unflagged.duplicate():
				flag(neighbour)
			return true
		# shared neighbourhoods
		for extended_neighbour in find_extended_uncovered_neighbours(square):
			var shared_neighbours: Array = find_shared_covered_unflagged_neighbours(square, extended_neighbour)
			if len(shared_neighbours) < len(square.neighbours_covered_unflagged):
				# flagging all squares that are definitely mines
				if len(square.neighbours_covered_unflagged) - len(shared_neighbours) == square.remaining_mines() - extended_neighbour.remaining_mines():
					for neighbour in square.neighbours_covered_unflagged.duplicate():
						if not neighbour in shared_neighbours:
							flag(neighbour)
					return true
				# uncovering all squares that are definitely not mines
				if len(shared_neighbours) == len(extended_neighbour.neighbours_covered_unflagged):
					if extended_neighbour.remaining_mines() == square.remaining_mines():
						for neighbour in square.neighbours_covered_unflagged.duplicate():
							if not neighbour in shared_neighbours:
								uncover(neighbour)
						return true
		# nothing can be done with the square
		interesting_squares.erase(square)
	return false

func update_mine_count() -> bool:
	
	var covered_squares: Array = covered_unflagged_squares()
	var bordering_squares: Array = find_bordering(covered_squares)
	var unreachable_squares: Array = find_unreachable(bordering_squares, covered_squares)
	var mines_remaining: int = mines_total - mines_flagged
	var safe_squares: Array = bordering_squares.duplicate()
	
	if mines_remaining > 0 and mines_remaining < 5 and len(covered_squares) < 10:
		var interesting_squares: Array = find_interesting(covered_squares)
		var correct_combinations: Array = flags_combinations(interesting_squares, bordering_squares, bordering_squares, unreachable_squares, mines_remaining)
		assert(not correct_combinations.empty())
		if len(safe_squares) > 0:
			for combination in correct_combinations:
				for safe_square in safe_squares.duplicate():
					if combination[bordering_squares.find(safe_square)] == 1:
						safe_squares.erase(safe_square)
		assert(len(correct_combinations) > 0)
		# only one correct combination
		if len(correct_combinations) == 1 and len(bordering_squares) > 0:
			var combination: Array = correct_combinations[0]
			for index in len(bordering_squares):
				if combination[index] == 0:
					uncover(bordering_squares[index])
			return true
		# some safe squares
		elif len(safe_squares) > 0:
			for square in safe_squares:
				uncover(square)
			return true
		# all mines bordering uncovered squares
		else:
			for combination in correct_combinations:
				if count_mines(combination) != mines_remaining:
					return false
			# all combinations have same number of mines
			if unreachable_squares.empty():
				return false
			for square in unreachable_squares:
				uncover(square)
			return true
	return false

func find_interesting(covered_squares: Array):
	var interesting: Array = []
	for covered in covered_squares:
		for neighbour in covered.neighbours_all:
			if not neighbour.covered and not neighbour in interesting:
				interesting.append(neighbour)
	return interesting

func find_bordering(covered_squares: Array):
	var bordering: Array = []
	for covered in covered_squares:
		for neighbour in covered.neighbours_all:
			if not neighbour.covered:
				bordering.append(covered)
				break
	return bordering
	
func find_unreachable(bordering_squares: Array, covered_squares: Array):
	var unreachable: Array = []
	for square in covered_squares:
		if not square in bordering_squares:
			unreachable.append(square)
	return unreachable

func flags_combinations(interesting_squares: Array, all_bordering_squares: Array, remaining_bordering_squares: Array, unreachable_squares: Array,  mines_remaining: int):
	var possible_combinations: Array = []
	var interesting_squares_copy: Array = interesting_squares.duplicate()
	var square: SolverSquare = null
	for possibly_interesting in interesting_squares.duplicate():
		if len(find_touching(possibly_interesting, remaining_bordering_squares)) == 0:
			if count_missing_flags(possibly_interesting) == 0:
				interesting_squares_copy.erase(possibly_interesting)
			else:
				return []
		else:
			square = possibly_interesting
			break
	if interesting_squares_copy.empty():
		if mines_remaining > len(unreachable_squares):
			return []
		else:
			var combination: Array = []
			for index in len(all_bordering_squares):
				combination.append(0)
			return [combination]
	else:
		var missing_flags: int = count_missing_flags(square)
		var touching = find_touching(square, remaining_bordering_squares)
		if missing_flags > len(touching):
			return []
		if missing_flags > mines_remaining:
			return []
		else: # missing_flags < len(touching)
			for neighbour in touching:
				if not neighbour.flagged:
					if neighbour in remaining_bordering_squares:
						neighbour.flagged = true
						var remaining_bordering_squares_copy: Array = remaining_bordering_squares.duplicate()
						remaining_bordering_squares_copy.erase(neighbour)
						if missing_flags == 1: # this was the last 
							interesting_squares_copy.erase(square)
							for neighbour_again in touching:
								remaining_bordering_squares_copy.erase(neighbour_again)
						for possibly_finished in neighbour.neighbours_all: # might have been last one for a different square
							if not possibly_finished.covered:
								var missing_flags_2: int = count_missing_flags(possibly_finished)
								if missing_flags_2 < 0:
									return []
								elif missing_flags_2 == 0:
									for finished_squares_neighbour in possibly_finished.neighbours_all:
										remaining_bordering_squares_copy.erase(finished_squares_neighbour)
						var suffixes = flags_combinations(interesting_squares_copy, all_bordering_squares, remaining_bordering_squares_copy, unreachable_squares, mines_remaining - 1)
						for suffix in suffixes:
							var combination: Array = []
							for index in len(all_bordering_squares):
								if index == all_bordering_squares.find(neighbour) or suffix[index] == 1:
									combination.append(1)
								else:
									combination.append(0)
							possible_combinations.append(combination)
						neighbour.flagged = false
		return possible_combinations

func count_mines(combination: Array):
	var count: int = 0
	for element in combination:
		count += element
	return count

func count_missing_flags(square: SolverSquare):
	var missing: int = square.mine_count
	for neighbour in square.neighbours_all:
		if neighbour.flagged:
			missing -= 1
	return missing

func find_touching(square: SolverSquare, bordering_squares: Array):
	var touching: Array = []
	for bordering_square in bordering_squares:
		if square in bordering_square.neighbours_all:
			touching.append(bordering_square)
	return touching

func covered_unflagged_squares():
	var covered: Array = []
	for x in len(squares):
		for y in len(squares[0]):
			var square: SolverSquare = squares[x][y]
			if square.covered and not square.flagged:
				covered.append(square)
	return covered

func uncover(square: SolverSquare):
	square.covered = false
	for neighbour in square.neighbours_all:
		neighbour.neighbours_covered_unflagged.erase(square)
	for neighbour in find_extended_uncovered_neighbours(square):
		if not neighbour in interesting_squares:
			interesting_squares.append(neighbour)
	interesting_squares.append(square)

func flag(square: SolverSquare):
	square.flagged = true
	for neighbour in square.neighbours_all:
		neighbour.flagged_count += 1
		neighbour.neighbours_covered_unflagged.erase(square)
	for neighbour in find_extended_uncovered_neighbours(square):
		if not neighbour in interesting_squares:
			interesting_squares.append(neighbour)
	mines_flagged += 1

func find_extended_uncovered_neighbours(square: SolverSquare):
	var extended_neighbours: Array = []
	for x in range(max(0, square.x - 2), min(len(squares), square.x + 3)):
		for y in range(max(0, square.y - 2), min(len(squares[0]), square.y + 3)):
			if not (x == square.x and y == square.y):
				var neighbour: SolverSquare = squares[x][y]
				if not neighbour.covered: # and neighbour.remaining_mines() != 0: <-this doesn't work for adding interesting_squares back, but maybe would work for solving
					extended_neighbours.append(neighbour)
	return extended_neighbours

func find_shared_covered_unflagged_neighbours(square1: SolverSquare, square2: SolverSquare):
	var shared_neighbours: Array = square1.neighbours_covered_unflagged.duplicate()
	for possibly_shared in square1.neighbours_covered_unflagged:
		if not possibly_shared in square2.neighbours_covered_unflagged:
			shared_neighbours.erase(possibly_shared)
	return shared_neighbours
