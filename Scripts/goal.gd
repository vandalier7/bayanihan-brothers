extends Node2D

class_name Goal

@export var sprite: Sprite2D
@export var completion: int
var requests = [0, 1, 2]

func _ready() -> void:
	for i in range(completion):
		requests.pop_at(0)
	update()

func update():
	if len(requests) == 3:
		sprite.visible = false
	elif len(requests) == 2:
		sprite.frame = 1
	elif len(requests) == 1:
		sprite.frame = 3
	elif len(requests) == 0:
		sprite.frame = 0
		Data.emit_signal("win")

func progress():	
	Data.emit_signal("playAudio", Data.stack, 8)
	update()
