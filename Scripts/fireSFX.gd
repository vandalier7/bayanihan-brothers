extends AudioStreamPlayer

var flameCount: int = 0
var fireSound = preload("res://SFX/fire.wav")
var targetDB
var actualDB

func increaseFlame():
	flameCount += 1
	recalculateVolume()
	
func decreaseFlame():
	flameCount -= 1
	#flameCount = max(flameCount, 0)
	recalculateVolume()

func recalculateVolume():
	if flameCount > 0:
		targetDB = min(0.2 + (flameCount/50.0), 0.6)
	else:
		targetDB = 0
	

func startSFX():
	clearSFX()
	stream = fireSound
	targetDB = 0
	actualDB = 0
	volume_db = linear_to_db(0.0) #.2 to .6
	play()

func clearSFX():
	flameCount = 0
	recalculateVolume()

func processFire(delta: float) -> void:
	actualDB = move_toward(actualDB, targetDB, delta)
	volume_db = linear_to_db(actualDB)
	#print(flameCount, " ", actualDB, " ", targetDB)
