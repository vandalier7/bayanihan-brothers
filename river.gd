extends Node2D

var bodies = []
@export var FLOAT_FORCE = 25
@export var flowSpeed = 15.0
@export var water_drag := 0.15
@export var water_angular_drag := 0.05
@export var isRiver: bool = false
@export var active: bool = false

@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var area = $FloatCollider


var submerged



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	area.monitoring = active

func _physics_process(delta: float) -> void:
	if not isRiver:
		return
	for body: Liftable in bodies:
		var depth
		if not body.customDepth:
			depth = global_position.y - body.top.global_position.y
		else:
			depth = body.depthEntry - body.top.global_position.y
			#print(depth)
		
		
		if depth > -50:
			body.linear_velocity.x = lerp(body.linear_velocity.x, flowSpeed, 0.1)
		#print(depth)
		if depth < 0:
			submerged = true
			if not body.freeze:
				body.apply_force((Vector2(0, max(FLOAT_FORCE * depth * gravity, -3000))))
			
		else:
			body.linear_velocity *=  1 - water_drag
			body.angular_velocity *= 1 - water_angular_drag 
		if body.isBurning:
			body.douse()
		if body.linear_velocity.y > 0:
			body.linear_velocity.y = lerp(body.linear_velocity.y, 0.0, 0.1)
		#print("RAAAA")


func onBodyEntered(body: Node2D) -> void:
	var i = 0
	
	
	
	if not isRiver:
		Data.emit_signal("levelEnd", Data.activeLevel, true)
		return
	
	if body.name == "Flame":
		body.get_parent().douse()
	
	elif body.name == "Feet":
		var player = body.get_parent()
		player.wade(true)
		
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
			elif player.linear_velocity.y > 100:
				Data.emit_signal("playAudio", Data.splashesIn[1])
			if player.linear_velocity.y > 100:
				player.splash.amount = round(player.linear_velocity.y - 92)/8
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
			
			
			bodies.append(body)
			
			



func onBodyExited(body: Node2D) -> void:
	if body.name == "Feet":
		body.get_parent().wade(false)
		#Data.emit_signal("playAudio", Data.splashesOut[0])
	if body.name == "Air":
		body.get_parent().submerge(false)
	else:
		bodies.erase(body)
		#Data.emit_signal("playAudio", Data.splashesOut[0])
