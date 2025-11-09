extends Node2D

@export var anima: AnimationPlayer
@export var audio: AudioStreamPlayer2D

func _ready() -> void:
	#await TimeUtil.wait(5)
	audio.volume_db = 8
	anima.play("credits", -1, 1.5)
	audio.play()
	await anima.animation_finished
	Data.goToMenu()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
