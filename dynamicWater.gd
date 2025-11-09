extends Node

@export var objects: Array[Node2D] = [null]
@export var periodic: bool = false
@export var speed: float = 10

func _physics_process(delta: float) -> void:
	for river in objects:
		river.position.y += -speed * delta
