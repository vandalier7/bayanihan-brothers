extends Liftable

class_name Bucket

var filled: bool = false
var amountHeld := 0
var waterHandler: WaterVisual 

var playerCoordinates: Vector2 # coordinates of the player in the water grid 

func _draw() -> void:
	pass

func _ready() -> void:
	super._ready()
	waterHandler = get_node("../WaterVisual")

var unfilledDir = [
	Vector2(1, 0),
	Vector2(1, 1),
	Vector2(1, 2),
	Vector2(2, 0),
	Vector2(2, 1),
	Vector2(2, 2),
	
	
	
]

var filledDir = [
	Vector2(0, 0)
]


func _process(delta: float) -> void:
	super._process(delta)

func getTargetCell(coordinates: Vector2, lastDir: int):
	var res = []
	if filled:
		
		for dir in filledDir:
			var cellCoord = coordinates + dir
			cellCoord.x += lastDir
			if waterHandler.checkIfWaterCell(cellCoord.x, cellCoord.y, 0):
				res.append(cellCoord)
	else:
		
		for dir in unfilledDir:
			var cellCoord = coordinates
			cellCoord.y += dir.y
			cellCoord.x += (lastDir * dir.x)
			if waterHandler.checkIfWaterCell(cellCoord.x, cellCoord.y):
				res.append(cellCoord)
	return res
	
func fill(value: bool):
	if value:
		filled = true
		$Sprite2D.frame = 1
	else:
		filled = false
		$Sprite2D.frame = 0
