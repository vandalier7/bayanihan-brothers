extends Button


func onClick():
	Data.emit_signal("levelEnd", Data.activeLevel)
