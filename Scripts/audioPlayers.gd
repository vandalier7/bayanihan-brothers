extends Node2D

class_name AudioPlayer

var players = []

func _ready() -> void:
	Data.connect("playAudio", Callable(self, "playSound"))
	for i in range(20):
		var player = AudioStreamPlayer2D.new()
		players.append(player)
		add_child(player)

func _exit_tree() -> void:
	Data.disconnect("playAudio", Callable(self, "playSound"))

func playSound(audio, volume = 0, start = 0):
	for audioPlayer: AudioStreamPlayer2D in players:
		if not audioPlayer.playing:
			audioPlayer.stream = audio
			audioPlayer.volume_db = volume
			audioPlayer.play(start)
			break
