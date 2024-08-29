extends Node

var num_levels = 2
var current_level = 0

var game_scene = "res://main.tscn"
var title_screen = "res://UI/title_screen.tscn"

func restart():
	current_level = 0
	get_tree().change_scene_to_file(title_screen)

func next_level():
	current_level += 1
	if current_level <= num_levels:
		get_tree().change_scene_to_file(game_scene)
