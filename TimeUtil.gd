# TimeUtils.gd (autoload)
extends Node

var timer: Timer

func _ready():
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)

func wait(seconds: float):
	timer.stop()
	timer.wait_time = seconds
	timer.start()
	return await timer.timeout
