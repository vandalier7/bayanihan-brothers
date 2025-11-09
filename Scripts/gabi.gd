extends Node2D

class_name Gabi

var vines = []
var interactionAllowed := true
@export var propagationInterval: float = 0.2
@export var openDuration: float = 5
@onready var leafAnim = $LeafAnim
@onready var leafPlatform = $Leaf/StaticBody2D/Platform
@onready var highlight = $Highlight
@onready var waterVisual = $"../WaterVisual"
var opened := false
var gridPos: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var i = 1
	while true:
		var node = get_node("Vine%d" % i)
		if not is_instance_valid(node):
			break
		vines.append(node)
		i += 1
	
	$RootAnim.play("rootLoop")
	gridPos = waterVisual.getCoordinateFromPosition(global_position)
	gridPos.y += 1
	print(gridPos)

# Called every frame. 'delta' is the elapsed time since the previous frame.
var dryTime = 0
var dryDuration = 2
func _process(delta: float) -> void:
	if waterVisual.waterGrid[gridPos.y][gridPos.x] > 2:
		dryTime = dryDuration
		if interactionAllowed:
			open()
			interactionAllowed = false
	else:
		dryTime = move_toward(dryTime, 0, delta)
		if dryTime == 0 and not interactionAllowed:
			interactionAllowed = true
			close()
		
func open():
	for i in len(vines):
		await get_tree().create_timer(propagationInterval).timeout
		for j in i + 1:
			if vines[j]. frame < 4:
				vines[j].frame += 1
	await get_tree().create_timer(propagationInterval/2.0).timeout
	leafAnim.play("open")
	await leafAnim.animation_finished
	activatePlatform(true)
	
	
	

func activatePlatform(value: bool):
	leafPlatform.set_deferred("disabled", not value)

func close():
	for i in len(vines):
		await get_tree().create_timer(propagationInterval).timeout
		for j in i + 1:
			if vines[j]. frame > 2:
				vines[j].frame -= 1
	await get_tree().create_timer(propagationInterval/2.0).timeout
	activatePlatform(false)
	leafAnim.play("close")
	await leafAnim.animation_finished
	
	

func showHighlight(value: bool):
	highlight.visible = value

func interact():
	open()
	interactionAllowed = false
	await get_tree().create_timer(propagationInterval * len(vines) + openDuration).timeout
	interactionAllowed = true
	
	close()
