@tool
extends Node2D

class_name WaterVisual

var areaScene = preload("res://Objects/waterArea.tscn")
var areas: Array = []

var columnBases = {}
@export var areaManager: Area2D

@export var areaPoolSize: int = 25
@export var width: int = 40:
	set(value):
		width = value
@export var height: int = 40:
	set(value):
		height = value
@export var cellSize: int = 16
@export var gridColor: Color:
	set(value):
		queue_redraw()
		gridColor = value
@export var blockColor: Color:
	set(value):
		queue_redraw()
		blockColor = value
@export var waterColor: Color = Color.DODGER_BLUE:
	set(value):
		queue_redraw()
		waterColor = value
@export var blocks: Array[Rect2]
@export var refresh: bool:
	set(value):
		_ready()
		queue_redraw()
		refresh = value
		
@export var initialWater: Array[Rect2]
@export var sources: Array[Vector2]
@export var fillers: Array[Rect2]
@export var bottoms: Array[Rect2]

var max_water := 7
var flow_rate := 7
var waterGrid: Array

func reset():
	if not Engine.is_editor_hint():
		for y in height:
			waterGrid.append([])
			for x in width:
				if Vector2i(x, y) in waterCoordinates:
					waterGrid[y].append(7)
				else:
					waterGrid[y].append(0)

				
				
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	blockCoordinates.clear()
	bakeBlockades()
	reset()

  # You can adjust this (1 to 7)



func flow(x: int, y: int, majorUpdate: bool) -> void:
	if waterGrid[y][x] <= 0:
		return
	
	if waterGrid[y][x] > max_water:
		var dirs = [
			Vector2(0, -1),   # Up
			Vector2(1, -1),
			Vector2(-1, -1)
		]
		var count: float = 0.0
		for dir in dirs:
			var nx = x + dir.x
			var ny = y + dir.y
			
			if nx < 0 or ny < 0 or nx >= width or ny >= height:
				continue
			if Vector2i(nx, ny) in blockCoordinates:
				continue
			count += 1
		var distribution = (waterGrid[y][x] - max_water) / max(1, count)
		for dir in dirs:
			var nx = x + dir.x
			var ny = y + dir.y
			
			if nx < 0 or ny < 0 or nx >= width or ny >= height:
				continue
			if Vector2i(nx, ny) in blockCoordinates:
				continue

			waterGrid[y][x] -= distribution
			waterGrid[ny][nx] += distribution
	
	var dirs = [
		Vector2(0, 1),   # Down
		Vector2(1, 1),
		Vector2(-1, 1)
	]
	if majorUpdate:
		for dir in dirs:
			var nx = x + dir.x
			var ny = y + dir.y
			
			if nx < 0 or ny < 0 or nx >= width or ny >= height:
				continue
			if waterGrid[ny][nx] == max_water:
				continue
			if Vector2i(nx, ny) in blockCoordinates:
				continue
			
			var from_water = waterGrid[y][x]
			var to_water = waterGrid[ny][nx]
			
			var space_available = 7 - to_water
			var amount_to_flow = min(flow_rate, from_water, space_available)
			
			if amount_to_flow > 0:
				waterGrid[y][x] -= amount_to_flow
				waterGrid[ny][nx] += amount_to_flow
				#return
	var amtRight = waterGrid[y][x]
	var amtLeft = waterGrid[y][x]
	if x > 0 and Vector2i(x - 1, y) not in blockCoordinates:
		amtLeft = waterGrid[y][x - 1]
	if x < width - 1 and Vector2i(x + 1, y) not in blockCoordinates:
		amtRight = waterGrid[y][x + 1]
	
	if amtLeft == amtRight and amtRight == waterGrid[y][x]:
		return
	
	var rightDiff = (amtRight - waterGrid[y][x])
	var leftDiff = (amtLeft - waterGrid[y][x])
	
	waterGrid[y][x] += (rightDiff + leftDiff)/2.0
	if x > 0:
		waterGrid[y][x - 1] -= leftDiff/2.0
	if x < width - 1:
		waterGrid[y][x + 1] -= rightDiff/2.0

func toWaterDisplay(amt: float, cap: bool = true):
	if cap:
		return -(min(amt/7.0, 1))*16
	else:
		return ((amt/7.0))*16

func _draw() -> void:
	if Engine.is_editor_hint():
		for y in height + 1:
			for x in width + 1:
				draw_line(Vector2(x * cellSize, -2 * cellSize), Vector2(x * cellSize, (height - 2) * cellSize), gridColor)
			draw_line(Vector2(0, (y - 2) * cellSize), Vector2(width * cellSize, (y - 2) * cellSize), gridColor)
		
		for rect in initialWater:
			var startX = rect.position.x * cellSize
			var startY = (rect.position.y - 2) * cellSize
			var endX = rect.size.x * cellSize
			var endY = (rect.size.y) * cellSize
			var translatedRect = Rect2(startX, startY, endX, endY)
			draw_rect(translatedRect, waterColor, true)
		for rect in blocks:
			var startX = rect.position.x * cellSize
			var startY = (rect.position.y - 2) * cellSize
			var endX = rect.size.x * cellSize
			var endY = (rect.size.y) * cellSize
			var translatedRect = Rect2(startX, startY, endX, endY)
			draw_rect(translatedRect, blockColor, false)
		for rect in bottoms:
			var startX = rect.position.x * cellSize
			var startY = (rect.position.y - 2) * cellSize
			var endX = rect.size.x * cellSize
			var endY = (rect.size.y) * cellSize
			var translatedRect = Rect2(startX, startY, endX, endY)
			draw_rect(translatedRect, Color.DARK_BLUE, false)
		for pos in sources:
			var x = (pos.x * cellSize) + (cellSize/2.0)
			var y = ((pos.y - 2) * cellSize) + (cellSize/2.0)
			draw_circle(Vector2(x, y), 4, Color.DARK_BLUE)
		for rect in fillers:
			var startX = rect.position.x * cellSize
			var startY = (rect.position.y - 2) * cellSize
			var endX = rect.size.x * cellSize
			var endY = (rect.size.y) * cellSize
			var translatedRect = Rect2(startX, startY, endX, endY)
			draw_rect(translatedRect, Color.LIGHT_BLUE, false)
	else:
		for y in height:
			for x in width:
				var amount = waterGrid[y][x]
				var xPos = x * (cellSize + 1) - (amount - 1)
				var yPos = y * (cellSize + 1) - (amount - 1)
				if amount <= 0.4: 
					continue
				#draw_circle(Vector2(xPos, yPos), amount * 1.5, Color.DODGER_BLUE)
				if isCellFalling(x, y):
					draw_rect(Rect2(x * cellSize, (y - 1) * cellSize, 16, -16), waterColor)
				else:
					if Vector2(x, y) in columnBases and false:
						var height = toWaterDisplay(calculateColumnDepth(x, y), false)
						draw_rect(Rect2(x * cellSize, (y - 1) * cellSize, 16, -height), waterColor)
						#var rect: Rect2 = Rect2(-8, shape.size.y/2, 16, -shape.size.y)
						#draw_rect(rect, Color.RED, false)
					draw_rect(Rect2(x * cellSize, (y - 1) * cellSize, 16, toWaterDisplay(amount)), waterColor)
					

# Called every frame. 'delta' is the elapsed time since the previous frame.

var majorUpdateInterval = 5
var majorFrame = 0

var updateInterval = 1
var frameUpdate = 0

var areaUpdateInterval = 0.25
var areaUpdateTime = 0

var areaEstablishInterval = 2.5
var areaEstablishTime = 0

func _process(delta: float) -> void:
	if areaEstablishTime <= 0:
		areaEstablishTime = areaEstablishInterval
		if not Engine.is_editor_hint():
			establishAreas()
	else:
		areaEstablishTime = move_toward(areaEstablishTime, 0, delta)
	
	if frameUpdate < updateInterval:
		frameUpdate += 1
		return
	frameUpdate = 0
	
	if majorFrame > 0:
		majorFrame -= 1
	else:
		majorFrame = majorUpdateInterval
	for y in range(height - 1, -1, -1):
		for x in range(width):
			if not Engine.is_editor_hint():
				flow(x, y, true)
				if Vector2(x, y) in columnBases:
					var height = toWaterDisplay(calculateColumnDepth(x, y), false)
					#print(x, " ", height)
					columnBases[Vector2(x, y)].updateShape(height)
	produce()
	queue_redraw()

var blockCoordinates: Dictionary = {}
var waterCoordinates: Dictionary = {}
func bakeBlockades():
	for rect in blocks:
		for x in range(int(rect.position.x), int(rect.position.x + rect.size.x)):
			for y in range(int(rect.position.y), int(rect.position.y + rect.size.y)):
				blockCoordinates[Vector2i(x, y)] = true
				
	for rect in initialWater:
		for x in range(int(rect.position.x), int(rect.position.x + rect.size.x)):
			for y in range(int(rect.position.y), int(rect.position.y + rect.size.y)):
				waterCoordinates[Vector2i(x, y)] = true
				
	for rect in bottoms:
		for x in range(int(rect.position.x), int(rect.position.x + rect.size.x)):
			for y in range(int(rect.position.y), int(rect.position.y + rect.size.y)):
				var column = DynamicWaterColumn.new(Vector2(x, y), cellSize)
				columnBases[Vector2(x, y)] = column
				areaManager.add_child(column)

func produce():
	if Engine.is_editor_hint():
		return
	for pos in sources:
		waterGrid[pos.y][pos.x] += 0.5
	for rect in fillers:
		for i in range(rect.position.x, rect.position.x + rect.size.x):
			for j in range(rect.position.y, rect.position.y + rect.size.y):
				if waterGrid[j][i] < 5: waterGrid[j][i] = 5

func isCellSideFlow(x, y):
	var hasAreaBelow = false
	var hasWaterAtLeft = true
	var hasWaterAtRight = true
	var heightLeft = 0
	var heightRight = 0
	# check for area below
	var dir = Vector2(0, 1)
	
	var nx = x + dir.x
	var ny = y + dir.y
		
	if nx < 0 or ny < 0 or nx >= width or ny >= height:
		return [-2, 0]
	if Vector2i(nx, ny) in blockCoordinates:
		return [-2, 0]
	
	# check for right water
	dir = Vector2(1, 0)
	nx = x + dir.x
	ny = y + dir.y
	if Vector2i(nx, ny) in blockCoordinates:
		return [-2, 0]
	if hasWaterAtRight and (nx < 0 or ny < 0 or nx >= width or ny >= height):
		hasWaterAtRight = false
	if hasWaterAtRight and Vector2i(nx, ny) in blockCoordinates:
		hasWaterAtRight = false
	if hasWaterAtRight and Vector2(nx, ny) in sources:
		return [1, 7]
	if hasWaterAtRight and isCellFalling(nx, ny):
		return [1, 7]
	if hasWaterAtRight and waterGrid[ny][nx] <= 0.1:
		hasWaterAtRight = false
	heightRight = waterGrid[ny][nx]
	
	
	dir = Vector2(-1, 0)
	nx = x + dir.x
	ny = y + dir.y
	if Vector2i(nx, ny) in blockCoordinates:
		return [-2, 0]
	if hasWaterAtLeft and (nx < 0 or ny < 0 or nx >= width or ny >= height):
		hasWaterAtLeft = false
	if hasWaterAtLeft and Vector2i(nx, ny) in blockCoordinates:
		hasWaterAtLeft = false
	if hasWaterAtLeft and Vector2(nx, ny) in sources:
		return [-1, 7]
	if hasWaterAtLeft and isCellFalling(nx, ny):
		return [-1, 7]
	if hasWaterAtLeft and waterGrid[ny][nx] <= 0.1:
		hasWaterAtLeft = false
	heightLeft = waterGrid[ny][nx]
	
	
	if hasWaterAtLeft and hasWaterAtRight: return [0, 0]
	if hasWaterAtLeft: return [-1, heightLeft]
	if hasWaterAtRight: return [1, heightRight]
	return [-2, 0]
	

func isCellSurrounded(x, y):
	var fill = true
	var dirs = [
		Vector2(1, 0),
		Vector2(-1, 0),
	]
	
	for dir in dirs:
		var nx = x + dir.x
		var ny = y + dir.y
		
		if nx < 0 or ny < 0 or nx >= width or ny >= height:
			continue
		if Vector2i(nx, ny) in blockCoordinates:
			continue
		if (waterGrid[ny][nx] != 7):
			return false
		return true

func isCellFalling(x, y):
	#var state = [false, false]
	var dirs = [
		Vector2(0, -1),
	]
	
	#var i = 0
	for dir in dirs:
		var nx = x + dir.x
		var ny = y + dir.y
		
		if nx < 0 or ny < 0 or nx >= width or ny >= height:
			return false
		if Vector2i(nx, ny) in blockCoordinates:
			return false
		if waterGrid[ny][nx] <= 0.4:
			return false
		return true
		
func getAreaInstance():
	for area in areas:
		if not area.active:
			return area

func updateAreas():
	pass
	
func establishAreas():
	pass

func calculateColumnDepth(x, y):
	if x < 0 or y < 0 or x >= width or y >= height:
		return 0
	var ny = y 
	var amtWater = 0.0
	while true:
		if ny < 0:
			break
		if waterGrid[ny][x] >= 7:
			amtWater += 7
		else:
			amtWater += waterGrid[ny][x]
			return amtWater
		ny -= 1
	return amtWater

func getPositionFromCoordinate(coordinate: Vector2):
	var x = coordinate.x * cellSize
	var y = (coordinate.y - 1) * cellSize
	var pos = to_global(Vector2(x, y))
	return pos
	
func fromWaterGridGlobal(pos: Vector2):
	return to_global(pos)

func checkIfWaterCell(x, y, requiredWater := 0.5):
	if x < 0 or y < 0 or x >= width or y >= height: return false
	if Vector2i(x, y) in blockCoordinates: return false
	if requiredWater and waterGrid[y][x] < requiredWater: return false
	return true

func addWater(x: int, y: int, amt: float):
	#assert(x < 0 or y < 0 or x >= width or y >= height, "Out of bounds!")
	waterGrid[y][x] += amt
	
func takeWater(x: int, y: int):
	var amt = waterGrid[y][x]
	#print(x, " ", y)
	waterGrid[y][x] = 0
	return amt

func getCoordinateFromPosition(globalPos: Vector2):
	var pos = to_local(globalPos)
	var x = floor(pos.x/cellSize)
	var y = floor(pos.y/cellSize)
	return Vector2(x, y)

func getColumnSurfaceAtPosition(pos):
	var coord = getCoordinateFromPosition(pos)
	var x = coord.x
	var y = coord.y
	var ny = y
	while true:
		if ny >= height - 1:
			break
		if Vector2(x, ny) in columnBases:
			break
		ny += 1 # go down
	
	var maxDepth = toWaterDisplay(calculateColumnDepth(x, ny), false)
	var bottom = getPositionFromCoordinate(Vector2(x, ny))
	
	return bottom.y - maxDepth
	

func objectFill(pos: Vector2, amount: float):
	var coord = getCoordinateFromPosition(pos)
	var x = coord.x
	var y = coord.y + 1
	
	if amount < 0:
		y += 1
	
	if x < 0 or x >= width or y < 0 or y >= height:
		return
	if Vector2i(x, y) in blockCoordinates:
		return
	waterGrid[y][x] += amount
	
