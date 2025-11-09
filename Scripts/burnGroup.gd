extends Node2D

class_name BurnGroup

var group: Array[Burnable] 
var finished: bool = false

func _ready() -> void:
	var temp = get_children()
	for body in temp:
		group.append(body)
	
func attemptDestroy():
	for body in group:
		if not body.burnt:
			return
	
	if finished:
		return
	
	finished = true
	
	for body in group:
		body.destroy()
		
