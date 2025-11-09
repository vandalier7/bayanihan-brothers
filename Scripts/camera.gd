extends Camera2D

@export var staticPosition: bool = false
@export var player1: Player1
@export var player2: Player1
@export var camOffset: Vector2
@export var threshold: float
@export var goal: Goal
var pos: Vector2
var bounds: Bounds

var rep: Array[Node2D] = [null, null]

func _ready() -> void:
	Data.connect("sendRep", Callable(self, "getRep"))
	bounds = get_node("../CamBounds")

func getRep(id: int, body: Node2D):
	id -= 1
	rep[id] = body

func getPos1():
	if player1.repped:
		return rep[1].global_position
	else:
		return player1.global_position

func clampPos(p: Vector2):
	var clampedX = clamp(p.x, bounds.leftBounds, bounds.rightBounds)
	var clampedY = clamp(p.y, bounds.upperBounds, bounds.lowerBounds)
	return Vector2(clampedX, clampedY)
	

func getPos2():
	if player2.repped:
		return rep[0].global_position
	else:
		return player2.global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if len(goal.requests) == 0:
		global_position = lerp(global_position, goal.global_position, 0.05)
		zoom = lerp(zoom, Vector2(2, 2), 0.01)
		return	
	if not Data.followCam or staticPosition:
		return
	var pos1 = getPos1()
	var pos2 = getPos2()
	pos = clampPos(((pos1 + pos2)*0.5) + camOffset)
	var res = lerp(global_position, pos, 0.05)
	global_position = Vector2(round(res.x), round(res.y))

	var dist = pos1.distance_to(pos2)
	if dist >= 440:
		var value = 440.0/dist
		zoom = lerp(zoom, Vector2(value, value), 0.05)
	else:
		zoom = lerp(zoom, Vector2(1, 1), 0.05)
