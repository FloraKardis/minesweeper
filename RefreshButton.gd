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
			get_button(level).texture_normal = load("res://Art/level" + str(level) + "_full" + easter_egg_suffix + ".png")
		else:
			get_button(level).texture_normal = load("res://Art/level" + str(level) + "_empty" + easter_egg_suffix + ".png")

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

# Easter egg

var using_easter_egg_assets: bool = false
var easter_egg_suffix: String = ""

func switch_assets():
	using_easter_egg_assets = not using_easter_egg_assets
	if using_easter_egg_assets:
		easter_egg_suffix = "_easter_egg"
	else:
		easter_egg_suffix = ""
	fill_up_to(current_level)
	for level in range(1, 4):
		get_button(level).texture_hover = load("res://Art/level" + str(level) + "_full" + easter_egg_suffix + ".png")
	$Circle/Left.texture = load("res://Art/refresh_idle_right" + easter_egg_suffix + ".png")
	$Circle/Right.texture = load("res://Art/refresh_idle_right" + easter_egg_suffix + ".png")
