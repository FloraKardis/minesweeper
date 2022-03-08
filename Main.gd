extends Node2D

const margin_left: int = 1 # * square_size
const margin_top:  int = 3 # * square_size

func _ready():
	randomize()
	$Board.position = Vector2(margin_left * Globals.square_size, 
							  margin_top  * Globals.square_size)
	$RefreshButton.rect_position = Vector2(
		(margin_left + float($Board.width) / 2 - 1) * Globals.square_size,
		(Globals.square_size - Globals.border_width) / 2)
	$RefreshButton.set_main(self)

func refresh(level: int):
	$Board.reset_board(level)

func switch_assets():
	$RefreshButton.switch_assets()
	$Board.switch_assets()
