extends Control

var main = null
var open = false
var current_level = 2

func set_main(main):
	self.main = main

func _on_AreaEnter_mouse_entered():
	if not open:
		$AnimationPlayer.play("Open")
		open = true

func _on_AreaExit_mouse_entered():
	if open:
		$AnimationPlayer.play_backwards("Open")
		open = false

func _on_Level_mouse_entered(level: int):
	fill_up_to(level)

func _on_Level_mouse_exited(level: int):
	fill_up_to(current_level)

func fill_up_to(target: int):
	for level in range(1, 4):
		if level <= target:
			get_button(level).texture_normal = load("res://Art/level" + str(level) + "_full.png")
		else:
			get_button(level).texture_normal = load("res://Art/level" + str(level) + "_empty.png")

func get_button(level: int):
	if level == 1:
		return $Levels/Level1
	if level == 2:
		return $Levels/Level2
	if level == 3:
		return $Levels/Level3


func _on_Level_pressed(level: int):
	current_level = level
	main.refresh(current_level)
