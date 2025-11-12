extends Node2D

@export var type = 0
var interval = 1
var timer = 0



func _process(delta: float) -> void:
	timer -= delta
	if timer <= 0:
		timer = interval
		get_child(0).frame = not (get_child(0).frame % 2)
		get_child(0).frame += 2 * type
