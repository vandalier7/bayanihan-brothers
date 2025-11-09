extends AudioStreamPlayer



var deathSound = preload("res://SFX/gameover.wav")

func playMusic():
	stream = deathSound
	play()
