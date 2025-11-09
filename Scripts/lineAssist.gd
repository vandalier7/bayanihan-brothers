extends Node2D

@export var length: int = 15
@export var initialSkips: int = 3
@export var baseSize = 0.5
@export_range(0, 10) var step: float = 0.025
@export var decayTime: float = 2
@export_range(0, 1) var decayPercentage: float = 0.3
@export_range(0, 1) var startingDecay: float = 0.9


var aimDuration: float
var angle: float
var velocity
var decay

func resetDecay() -> void:
	decay = startingDecay

func _draw() -> void:
	var points = []
	var gravity = 980
	velocity = 400 * Vector2(cos(deg_to_rad(angle)), sin(deg_to_rad(angle)))
	for i in range(length):
		if i < initialSkips:
			continue
		var t = i * step
		var pos = Vector2.ZERO + Vector2(
			velocity.x * t,
			velocity.y * t + 0.5 * gravity * t * t
		)
		points.append(pos)
	
	if aimDuration > decayTime:
		decay = move_toward(decay, decayPercentage, 0.0075)
	
	var i: float = 0
	for point in points:
		i += 1.0/float(len(points))
		draw_circle(point, baseSize + (1 - i), Color.RED)
		#else:
			#draw_circle(point, baseSize * startingDecay + (1 - i) * decay, Color(1, 0, 0, ((1 - i)/1 - decay) - 0.1))
			

func _process(delta: float) -> void:
	queue_redraw()
