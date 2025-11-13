extends Node2D

@export var waterLevel: bool
@onready var levelTitle: Label = get_node("UI/Welcome/Panel/Label")
@onready var animator: AnimationPlayer = get_node("AnimationPlayer")
@export var levelID: int = 0
@export var zoomedPreview := true

var titleDisplay: Label

var players: Array[Player1]

func _process(delta: float) -> void:
	FireSfx.processFire(delta)

func assignController(accept):
	#print("Attempting to assign controller to Player %d")
	rpc("connectPlayer", accept)

@rpc("any_peer")
func connectPlayer(id: int):
	pass

func _ready() -> void:
	var cam: Camera2D = $Camera2D
	cam.zoom = Vector2(1, 1)
	players.append($player1)
	players.append($player2)
	#Data.addContoller()
	FireSfx.startSFX()
	Data.connect("assignController", Callable(self, "assignController"))
	Data.connect("levelEnd", Callable(self, "endLevel"))
	Data.connect("win", Callable(self, "winAnim"))
	Data.emit_signal("levelStart")
	
	levelTitle.text = Data.titles[levelID]
	titleDisplay = $UI/Title
	titleDisplay.text = Data.titles[levelID] + " "
	$UI/Transition.visible = true
	var hideOnIntro = [$UI/Sprite2D, $UI/Title, $"Gameplay Text"]
	for item in hideOnIntro:
		item.visible = false
	if Data.showTitle[levelID]:
		
		Bgm.playBgm()
		
		if zoomedPreview:
			cam.zoom = Vector2(2, 2)
		var originalCamState = [cam.staticPosition, cam.global_position]
		cam.staticPosition = true
		animator.play("start")
		await animator.animation_finished
		
		cam.staticPosition = originalCamState[0]
		cam.global_position = originalCamState[1]
		cam.zoom = Vector2(1, 1)
	for item in hideOnIntro:
		item.visible = true
	Bgm.playBgm()
	animator.play("intro")
	await animator.animation_finished
	Data.allowInput = true
	
	

func winAnim():
	won = true
	Data.allowInput = false
	animator.play("win")
	await TimeUtil.wait(0.3)
	Data.emit_signal("playAudio", Data.levelComplete, 4)
	await animator.animation_finished
	Data.emit_signal("levelEnd", Data.nextLevel(), false)
	
var won: bool = false
func endLevel(next: int, playDeath: bool = false):
	if (not Data.allowInput and not won):
		return
	if playDeath:
		GlobalPlayer.playMusic()
		Bgm.makeWayForDeath()
	Data.allowInput = false
	Data.followCam = false
	animator.play("intro", -1, -1, true)
	await animator.animation_finished
	Data.followCam = true
	if next == -2:
		Data.showCredits()
	elif next == -1:
		Data.goToMenu()
	else:
		Data.startLevel(next, next != Data.activeLevel)

@rpc("any_peer")
func processControllerInput(data):
	if Data.controllers.has(data["ID"]) and Data.controllers[data["ID"]]:
		players[data["ID"] - 1].input = data
	
@rpc("any_peer")
func processState(data):
	pass

func broadcastState(data):
	rpc("processState", data)
