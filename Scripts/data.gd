extends Node

signal playAudio(audio, volume, start)
signal sendRep(body)
signal levelEnd(next: int, playDeath: bool)
signal win
signal checkCarries
signal levelStart
signal assignController(id: int)

var followCam = true
var activeLevel: int 
var throwable = preload("res://Objects/throwable.tscn")
var throwSprite = preload("res://Textures/Player/idle1.png")
var allowInput: bool = false

var menu = preload("res://Objects/mainmenu.tscn")

var controllers = {
	1 : false,
	2 : false,
}

var levels = {
	0 : preload("res://Levels/tutorial.tscn"),
	1 : preload("res://Levels/level1.tscn"),
	2 : preload("res://Levels/level3.tscn"),
	3 : preload("res://Levels/level4.tscn"), #mind the gap
	4 : preload("res://Levels/level2.tscn"),
	5 : preload("res://Levels/level5.tscn"),
	6 : preload("res://Levels/level6.tscn"), #catch this!
	7 : preload("res://Levels/level7.tscn"),
	8 : preload("res://Levels/level8.tscn"),
	9 : preload("res://Levels/level9.tscn"),
	10 : preload("res://Levels/level10.tscn"),
	11 : preload("res://Levels/level11.tscn"),
	12 : preload("res://Levels/level12.tscn"),
	13 : preload("res://Levels/level13.tscn"),
	14 : preload("res://Levels/level14.tscn"),
	15 : preload("res://Levels/level15.tscn"),
	16 : preload("res://Levels/level16.tscn"),
	17 : preload("res://Levels/level17.tscn"),
	18 : preload("res://Levels/level18.tscn"),
	19 : preload("res://Levels/level19.tscn"),
	20 : preload("res://Levels/level20.tscn"),
	
	
	
	
	
		
}

var titles = {
	0 : "Building a Hut",
	1 : "The Bayanihan Brothers",
	2 : "Heave-Ho",
	3 : "Mind the Gap",
	4 : "Airdrop",
	5 : "Catch This!",
	6 : "Grab Me!",
	7 : "Trust Fall",
	8 : "Raft",
	9 : "Across the River",
	10 : "Hauling Cargo",
	11 : "Cave Adventures",
	12 : "Air Pocket",
	13 : "Shallow Trouble",
	14 : "Rescue Mission",
	15 : "Hephaestus",
	16 : "Double-Edged",
	17 : "Fire Drop",
	18 : "Burnt Bridges",
	19 : "Catching Fire",
	20 : "Torch Relay"
	
	
	
	
	
}
var showTitle = [
	true, true, true, true, true,
	true, true, true, true, true,
	true, true, true, true, true,
	true, true, true, true, true,
	true, true, true, true, true,
	
]

var creds = preload("res://Levels/credits.tscn")

var throw = preload("res://SFX/throw2.wav")
var levelComplete = preload("res://SFX/levelComplete.wav")
var stack = preload("res://SFX/stack2.wav")
var pickup = preload("res://SFX/pick.wav")
var walk = preload("res://SFX/walk2.wav")
var jump = preload("res://SFX/jump.wav")
var splashesIn = [
	preload("res://SFX/in1.wav"),
	preload("res://SFX/in2.wav"),
	preload("res://SFX/in3.wav"),
]
var drown = preload("res://SFX/drown.wav")
var steam = preload("res://SFX/steam.wav")

var splashesOut = [
	preload("res://SFX/out.wav")
]

var erupt = preload("res://SFX/erupt.wav")

var peer

func startControllerServer():
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(135)
	if result != OK:
		print("Failed to start WebSocket server:", result)
	else:
		print("WebSocket server started")
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(addController)
	multiplayer.peer_disconnected.connect(removeControllers)

func removeControllers(id):
	pass

func addController(accept: bool):
	emit_signal("assignController", accept) # argument doesnt matter
	

func _on_peer_connected(id):
	print("Client connected with ID:", id)

func _on_peer_disconnected(id):
	print("Client disconnected with ID:", id)

	

func startLevel(level: int, show: bool = false):
	showTitle[level] = show
	activeLevel = level
	get_tree().change_scene_to_packed(levels[level])

func goToMenu():
	get_tree().change_scene_to_packed(menu)

func showCredits():
	get_tree().change_scene_to_packed(creds)

func nextLevel():
	var maxLevel = len(levels) - 1
	if activeLevel + 1 <= maxLevel:
		return activeLevel + 1
	else:
		if maxLevel == 21:
			Bgm.stop()
			return -2
		else:
			return activeLevel
