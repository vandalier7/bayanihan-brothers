extends Node2D

@export var sprite: Texture2D
var interval = 1
var timer = 0

func _ready() -> void:
	get_child(0).texture = sprite

func _process(delta: float) -> void:
	timer += delta
	if interval < timer:
		timer = 0
		get_child(0).frame = not get_child(0).frame
