extends Node

func _ready() -> void:
	var level_num = str(GameState.current_level).pad_zeros(2)
	var path = "res://Levels/level_%s.tscn" % level_num
	var level = load(path).instantiate()
	add_child(level)
