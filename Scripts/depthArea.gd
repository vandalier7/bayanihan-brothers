extends Node2D

class_name Depth


func onBodyEntered(body: Node2D) -> void:
	if is_instance_of(body, Liftable):
		body.depthOverride(true, global_position.y)


func onBodyExited(body: Node2D) -> void:
	if is_instance_of(body, Liftable):
		body.depthOverride(false)
