extends Button

@export var level: int
var animator: AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animator = get_node("../../../../AnimationPlayer")


func onPress() -> void:
	animator.play("transition")
	await animator.animation_finished
	Data.startLevel(level-1, true)
	Bgm.stop()
