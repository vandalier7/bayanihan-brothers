extends AudioStreamPlayer



var sound = preload("res://SFX/Bahay Kubo BGM.wav")
var bgm = preload("res://SFX/levelbgm.wav")

func playMusic():
	if playing:
		return
	stream = sound
	volume_db = 0
	play()

func playBgm():
	if playing: return
	stream = bgm
	volume_db = 2
	play()

func makeWayForDeath(time: float = 1.5):
	volume_db = -40
	#stream_paused = true
	await get_tree().create_timer(2).timeout
	volume_db = 2
	#stream_paused = false
