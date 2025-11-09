extends Sprite2D

class_name Bounds

@export var pointA: Node2D
@export var pointB: Node2D

var upperBounds
var lowerBounds
var leftBounds
var rightBounds

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	upperBounds = pointA.global_position.y
	lowerBounds = pointB.global_position.y
	leftBounds = pointA.global_position.x
	rightBounds = pointB.global_position.x


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
