extends Area2D

var bodies = []
@export var FLOAT_FORCE = 25
@export var flowSpeed = 15.0
@export var water_drag := 0.15
@export var water_angular_drag := 0.05
@export var isRiver: bool = false
@export var active: bool = false
@export var waterHanlder: WaterVisual
@onready var g: float = ProjectSettings.get_setting("physics/3d/default_gravity")


var submerged


# Called every frame. 'delta' is the elapsed time since the previous frame.
var updateInterval = 0.25
var updateTime = 0

func _physics_process(delta: float) -> void:
	if not isRiver:
		return
	for body: Liftable in bodies:
		var depth
		if true:
			if updateTime == 0:
				body.surfaceLevel = waterHanlder.getColumnSurfaceAtPosition(body.global_position)
				#print(body.surfaceLevel)
			depth = body.surfaceLevel - body.global_position.y
			#print(body.surfaceLevel)
		
		
		if true:
			body.linear_velocity.x = lerp(body.linear_velocity.x, flowSpeed, 0.1)
		#print(depth)
		if depth < 0:
			submerged = true
			if not body.freeze:
				var f = max(FLOAT_FORCE * -1 * g, 25 * depth * g)
				#print(f)
				body.apply_force((Vector2(0, f)))
				
			
		else:
			body.linear_velocity *=  1 - water_drag
			body.angular_velocity *= 1 - water_angular_drag 
		if body.isBurning:
			body.douse()
		if body.linear_velocity.y > 0:
			body.linear_velocity.y = lerp(body.linear_velocity.y, 0.0, 0.1)
		#print("RAAAA")
	if updateTime == 0:
		updateTime = updateInterval
	else:
		updateTime = move_toward(updateTime, 0, delta)


func onBodyEntered(body: Node2D) -> void:
	var i = 0
	
	updateTime = 0
	
	if not isRiver:
		Data.emit_signal("levelEnd", Data.activeLevel, true)
		return
	
	if body.name == "Flame":
		body.get_parent().douse()
	
	elif body.name == "Feet":
		var player = body.get_parent()
		player.wade(true)
		waterHanlder.objectFill(player.global_position, player.volume)
		
		if is_instance_of(player, Player1):
			if player.velocity.y > 150:
				Data.emit_signal("playAudio", Data.splashesIn[0])
			elif player.velocity.y > 100:
				Data.emit_signal("playAudio", Data.splashesIn[1])
				
			if player.velocity.y > 100:
				player.splash.amount = round(player.velocity.y - 92)/8
				player.splash.initial_velocity_min = (min(player.velocity.y, 300) - 25)
				player.splash.initial_velocity_max = (min(player.velocity.y, 300) + 25)
				player.splash.restart()
			player.velocity.x *= 0.3
			player.velocity.y *= 0.3
			
		elif is_instance_of(player, Throwable):
			player.collide()
			if player.linear_velocity.y > 200:
				Data.emit_signal("playAudio", Data.splashesIn[0])
			elif player.linear_velocity.y > 50:
				Data.emit_signal("playAudio", Data.splashesIn[1])
			if player.linear_velocity.y > 50:
				player.splash.amount = round(player.linear_velocity.y - 46)/4
				player.splash.initial_velocity_min = (min(player.linear_velocity.y, 300) - 25)
				player.splash.initial_velocity_max = (min(player.linear_velocity.y, 300) + 25)
				player.splash.restart()
			player.linear_velocity.x *= 0.3
			#player.linear_velocity.y /= pow(abs(player.linear_velocity.y), 0.5)
			#print(player.linear_velocity)
			
			
		
	
	elif body.name == "Air":
		#Engine.time_scale = 0
		#await get_tree().create_timer(1, true, false, true).timeout
		#Engine.time_scale = 1
		
		body.get_parent().submerge(true)
		
		#Data.emit_signal("levelEnd", Data.activeLevel)
		#GlobalPlayer.playMusic()
		#Bgm.makeWayForDeath()
	else:
		waterHanlder.objectFill(body.global_position, body.volume)
		if body.floats:
			if body.linear_velocity.y > 100:
				Data.emit_signal("playAudio", Data.splashesIn[0])
			elif body.linear_velocity.y > 100:
				Data.emit_signal("playAudio", Data.splashesIn[1])
			if body.linear_velocity.y > 100:
				body.splash.amount = round(body.linear_velocity.y - 92)/8
				body.splash.initial_velocity_min = (min(body.linear_velocity.y, 300) - 25)
				body.splash.initial_velocity_max = (min(body.linear_velocity.y, 300) + 25)
				#print(body.splash.initial_velocity_max)
				body.splash.restart()
			
			body.linear_velocity.y *= 0.3
			bodies.append(body)
			
			



func onBodyExited(body: Node2D) -> void:
	if not isRiver:
		return
	
	if body.name == "Feet":
		body.get_parent().wade(false)
		waterHanlder.objectFill(body.get_parent().global_position, -body.get_parent().volume)
		
		#Data.emit_signal("playAudio", Data.splashesOut[0])
	if body.name == "Air":
		body.get_parent().submerge(false)
	else:
		if is_instance_of(body, Liftable):
			waterHanlder.objectFill(body.global_position, -body.volume)
			body.linear_velocity.y *= 0.7
			bodies.erase(body)
		#Data.emit_signal("playAudio", Data.splashesOut[0])
