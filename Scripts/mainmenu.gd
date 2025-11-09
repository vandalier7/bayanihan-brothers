extends Control

var waterLevel: bool
var mainMenu: Control
var levelMenu: Control

func _ready() -> void:
	
	#DisplayServer.window_set_size(screen_size)
	Data.connect("assignController", Callable(self, "assignController"))
	$"Main Menu/Player1".button_pressed = Data.controllers[1]
	$"Main Menu/Player2".button_pressed = Data.controllers[2]
	mainMenu = $"Main Menu"
	levelMenu = $"Level Menu"
	Bgm.playMusic()
	Data.startControllerServer()
	
	refreshIP()
	
var ping = 0
var pingInterval: int = 100 #frames
func _process(delta: float) -> void:
	if ping < pingInterval:
		ping += 1
	else:
		refreshIP()
		ping = 0
		
	

func refreshIP():
	var ip = ""
	#print(IP.get_local_addresses())
	for i in IP.get_local_addresses():
		if i.is_valid_ip_address() and (i.begins_with("192.168") or i.begins_with("10.") or i.begins_with("172.")):
			ip = i
			break

	$"Main Menu/IP".text = ip

func openLevelMenu():
	mainMenu.visible = false
	levelMenu.visible = true
	


func _on_exit_pressed() -> void:
	get_tree().quit()


func toggle1(toggled_on: bool) -> void:
	if toggled_on:
		Data.controllers[1] = true
	else:
		Data.controllers[1] = false
		
func toggle2(toggled_on: bool) -> void:
	if toggled_on:
		Data.controllers[2] = true
	else:
		Data.controllers[2] = false


func assignController(accept):
	#print("Attempting to assign controller to Player %d")
	rpc("connectPlayer", accept)

@rpc("any_peer")
func connectPlayer(id: int):
	pass
	
@rpc("any_peer")
func processControllerInput(data):
	pass
	
@rpc("any_peer")
func processState(data):
	pass
	
func broadcastState(data):
	rpc("processState", data)
