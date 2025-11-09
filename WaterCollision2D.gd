extends CollisionShape2D

class_name DynamicWaterColumn

var height: float = 0 # in water units; 7 water units = 16px
var bottom: int
var xPos: int
var cellSize: int

func _init(tileCoord: Vector2, cSize: int) -> void:
	var baseShape: RectangleShape2D = RectangleShape2D.new()
	cellSize = cSize
	baseShape.size = Vector2(16, 16)
	shape = baseShape
	bottom = tileCoord.y + 1
	xPos = tileCoord.x
	#position = Vector2(tileCoord.x * cellSize + 8, 0)
	updateShape(0)
func _draw() -> void:
	var rect: Rect2 = Rect2(-8, -shape.size.y/2.0 - 2, 16, 2)
	var color
	if shape.size.y > 2:
		color = Color.SKY_BLUE
		color.a = 0.9
		draw_rect(rect, Color.SKY_BLUE, true, -1, true)
	if shape.size.y > 5:
		color = lerp(Color.SKY_BLUE, Color.DODGER_BLUE, 0.2)
		color.a = 0.5
		rect = Rect2(-8, (-shape.size.y/2.0), 16, 3)
		draw_rect(rect, color, true, -1, true)
	if shape.size.y > 11:
		color = lerp(Color.SKY_BLUE, Color.DODGER_BLUE, 0.5)
		color.a = 0.4
		rect = Rect2(-8, (-shape.size.y/2.0) + 3, 16, 6)
		draw_rect(rect, color, true)
	if shape.size.y > 23:
		color = lerp(Color.SKY_BLUE, Color.DODGER_BLUE, 0.85)
		color.a = 0.3
		rect = Rect2(-8, (-shape.size.y/2.0) + 9, 16, 12)
		draw_rect(rect, color, true)

func updateShape(heightInPixels: int):
	shape.size.y = max(heightInPixels, 0)
	if heightInPixels > 0:
		position = Vector2(xPos * cellSize + 8, ((bottom) * cellSize) - (heightInPixels/2.0))
		#print(heightInPixels)
		queue_redraw()
	else:
		global_position = Vector2(-199, -199)
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
