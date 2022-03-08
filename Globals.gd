extends Node

var square_size:  int = load("res://Art/square_uncovered.png").get_size().x
var border_width: int = load("res://Art/border_vertical.png").get_size().x
var active_square: Square = null
var board_locked: bool = false
