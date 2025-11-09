extends CharacterBody2D

class_name Player1

var waterHandler: WaterVisual
var selected: PhysicsBody2D
var goal: Goal
@export var lastDir: int
var originalLayer
var originalMask
var carried:= false
var carrying:= false
var aiming: bool = false

var carriedZ = 0

var interactCooldown = 0.25
var cdTimer = 0.0

var pickupCooldown = 0.5
var pickupTimer = 0.0

var submerged: bool = false
var waded: bool = false
var onBuild := false

@export var id: int = 1
@export var mercyJump: float = 0.1
@export var jumpBuffer: float = 0.1
@export var throwForce: float = 420
@export var volume: float = 3.0
var mercyJumpTimer: float = 0
var bufferTimer: float = 0
var SPEED = 120.0
var JUMP_VELOCITY = -300.0
var HOP_VELOCITY = -60

var originalSpeed
var originalJump
var originalHop

var sprite: Sprite2D
var bubbles: CPUParticles2D
var anime: AnimationPlayer
var carrySlot: Node2D
var drop: Node2D
var aimAssist: Sprite2D
var lineAssist: Node2D
var pickup: Node2D
var build: Node2D
@onready var interact = $Interact
var torchCatch: Node2D
var highlight: Sprite2D
var splash: CPUParticles2D

@export var breath: float = 5
@export var breathBar: Sprite2D
var remainingBreath: float 
var dead: bool = false
var barAnim: AnimationPlayer
var playerAnim: AnimationPlayer

func wade(value: bool):
	waded = value
	if value:
		SPEED = (originalSpeed/3)*2
		#JUMP_VELOCITY = (originalJump/5)*4
		#HOP_VELOCITY = (originalHop/5)*4
	else:
		SPEED = originalSpeed
		JUMP_VELOCITY = originalJump
		HOP_VELOCITY = originalHop

func submerge(value: bool):
	submerged = value
	bubbles.emitting = value
	if not submerged:
		barAnim.pause()
		#SPEED = originalSpeed
		#JUMP_VELOCITY = originalJump
		#HOP_VELOCITY = originalHop
	else:
		barAnim.play("RESET")
		#SPEED = (originalSpeed/3)*2
		#JUMP_VELOCITY = (originalJump/5)*4
		#HOP_VELOCITY = (originalHop/5)*4

func levelStart():
	remainingBreath = breath

func _ready() -> void:
	playerAnim = $AnimationPlayer
	Data.connect("levelStart", Callable(self, "levelStart"))
	if get_parent().waterLevel:
		waterHandler = get_node("../WaterVisual")
	bubbles = get_node("Bubbles")
	highlight = get_node("Highlight")
	sprite = get_node("Sprite2D")
	anime = get_node("AnimationPlayer")
	carrySlot = get_node("Slot")
	drop = get_node("Drop")
	pickup = get_node("PickUp")
	torchCatch = get_node("TorchCatcher")
	aimAssist = get_node("AimAssist")
	lineAssist = get_node("AimAssist/LineAssist")
	build = get_node("Build")
	#goal = $"../Goal"
	originalLayer = collision_layer
	originalMask = collision_mask
	
	originalHop = HOP_VELOCITY
	originalJump = JUMP_VELOCITY
	originalSpeed = SPEED
	
	Data.connect("checkCarries", Callable(self, "checkCarry"))
	barAnim = $BarAnim
	splash = $Splash
	barAnim.play("RESET")
	
	statuses["ID"] = id


func overrideBreath(value: float):
	remainingBreath = breath

var angle: float
var multi = -1
var aimDuration: float = 0
var easingThreshold = 20.0
func aim(delta: float):
	if cdTimer > 0:
		return
	aimDuration += delta
		
	if angle <= -89:
		multi = 1
	if angle >= 9:
		multi = -1
	if lastDir > 0:
		#aimAssist.rotation_degrees = angle
		lineAssist.angle = angle
	else:
		#aimAssist.rotation_degrees = 180 - angle
		lineAssist.angle = 180 - angle
	lineAssist.aimDuration = aimDuration
	
	if multi < 0:
		if angle > 10 - easingThreshold:
			angle += multi * 2.0 * clamp(1.0 - (-(10 - angle) / easingThreshold), 0.1, 1.0)
		elif angle < -90 + easingThreshold:
			angle += multi * 2.0 * clamp((90 + angle)/easingThreshold, 0.1, 1.0)
		else:
			angle += multi * 2.0 #up
			
	else:
		if angle < -90 + easingThreshold:
			angle += multi * 1.9 * clamp((90 + angle)/easingThreshold, 0.1, 1.0)
		elif angle > 10 - easingThreshold:
			angle += multi * 1.9 * clamp(1.0 - (-(10 - angle) / easingThreshold), 0.1, 1.0)
		else:
			angle += multi * 1.9 #down
	

func unitVector(degrees: float) -> Vector2:
	var radians = deg_to_rad(degrees)
	return Vector2(cos(radians), sin(radians))



var throwAnim: bool = false
var repped: bool = false
func throw(degrees):
		if cdTimer > 0:
			return
		statuses["CARRYING"] = false
		if not carried:
			get_parent().broadcastState(statuses)
		pickupTimer = pickupCooldown
		throwAnim = true
		aimAssist.visible = false
		sprite.frame = 24
		await get_tree().create_timer(0.15).timeout
		sprite.frame = 25
		var force = unitVector(degrees) * throwForce
		
		carrying = false
		var body: PhysicsBody2D = carrySlot.get_child(0)
		carryBucket(false)
		
		
		body.get_parent().remove_child(body)
		body.z_index = carriedZ
		body.z_as_relative = true
		
		body.position = carrySlot.global_position
		
		Data.emit_signal("playAudio", Data.throw, 3, 0.36)
		
		if is_instance_of(body, RigidBody2D):
			if is_instance_of(body, Torch):
				body.setThrown()
			get_tree().current_scene.add_child(body)
			body.freeze = false
			body.collision_layer = body.originalLayer
			body.collision_mask = body.originalMask
			body.linear_velocity = Vector2(force.x * lastDir, force.y)
			
		if is_instance_of(body, CharacterBody2D):
			throwSubstitute(body, force)
		await get_tree().create_timer(0.1).timeout
		throwAnim = false

func substitute(force):
	if carrying and carrySlot.get_child_count() > 0:
		letGo()
	visible = false
	var throwObject: Throwable = Data.throwable.instantiate()
	Data.emit_signal("sendRep", id, throwObject)
	throwObject.commit(self)
	throwObject.spawn = false
	get_tree().current_scene.call_deferred("add_child", throwObject)
	throwObject.position = global_position
	throwObject.linear_velocity = Vector2(force.x, force.y)

func throwSubstitute(body, force):
			body.carried = false
			body.repped = true
			var throwObject: Throwable = Data.throwable.instantiate()
			Data.emit_signal("sendRep", id, throwObject)
			if lastDir == -1:
				throwObject.sprite.flip_h = true
			throwObject.commit(body)
			
			#throwObject.sprite.texture = Data.throwSprite
			get_tree().current_scene.add_child(throwObject)
			throwObject.position = carrySlot.global_position
			throwObject.linear_velocity = Vector2(force.x * lastDir, force.y)

func stack():
	var body = carrySlot.get_child(0)
	
	if is_instance_of(body, Player1):
		return false
	
	if len(goal.requests) == 0 or body.id != goal.requests[0]:
		return false
	
	if body.isBurning:
		return
	
	statuses["CARRYING"] = false
	get_parent().broadcastState(statuses)
	
	goal.requests.pop_at(0)
	goal.progress()
	aimAssist.visible = false
	carrying = false
		
	body.get_parent().remove_child(body)
	
	goal.sprite.visible = true
	return true

func letGo(currScene = null):
		if throwAnim:
			return
		statuses["CARRYING"] = false
		get_parent().broadcastState(statuses)
		
		angle = 10
		aimDuration = 0
		lineAssist.resetDecay()
		aiming = false
		aimAssist.visible = false
		carrying = false
		var body: PhysicsBody2D = carrySlot.get_child(0)
		carryBucket(false)
		if is_instance_of(body, Torch):
			body.setStanding()
		body.get_parent().remove_child(body)
		body.z_index = carriedZ
		body.z_as_relative = true
		body.position = carrySlot.global_position
		
		if is_instance_of(body, RigidBody2D):
			if not currScene:
				get_tree().current_scene.call_deferred("add_child", body)
			else:
				pass
			body.freeze = false
			body.collision_layer = body.originalLayer
			body.collision_mask = body.originalMask
			body.linear_velocity = Vector2(lastDir * 100, -100)
		if is_instance_of(body, CharacterBody2D):
			body.carried = false
			body.repped = true
			var throwObject: Throwable = Data.throwable.instantiate()
			Data.emit_signal("sendRep", id, throwObject)
			if lastDir == -1:
				throwObject.sprite.flip_h = true
			throwObject.commit(body)
			
			#throwObject.sprite.texture = Data.throwSprite
			get_tree().current_scene.add_child(throwObject)
			throwObject.position = carrySlot.global_position
			throwObject.linear_velocity = Vector2(lastDir * 100, -100)
var finalCheck
func carry():
		if pickupTimer > 0:
			return
		statuses["CARRYING"] = true
		get_parent().broadcastState(statuses)
		
		
		
		cdTimer = interactCooldown
		angle = 10
		lineAssist.resetDecay()
		aimDuration = 0
		carrying = true
		var body: PhysicsBody2D = selected
		
		carryBucket(true, body)
		
		if is_instance_of(body, Torch):
			if not body.liftable:
				carrying = false
				return
			body.setCarry()
		finalCheck = selected
		selected.get_parent().remove_child(body)
		body.position = Vector2(0, 0)
		
		Data.emit_signal("playAudio", Data.pickup, 0)
		carrySlot.add_child(body)
		carriedZ = body.z_index
		body.z_index = -1
		body.z_as_relative = false
		if is_instance_of(body, Liftable):
			body.freeze = true
			
			if not is_instance_of(body, Torch) and not is_instance_of(body, Bucket):
				if id == 1:
					body.collision_layer = 2
					body.collision_mask = 2
				if id == 2:
					body.collision_layer = 1
					body.collision_mask = 1
			else:
				body.collision_layer = 64
				body.collision_mask = 64
			#body.collision_layer = 8192 + 64
			#body.collision_mask = 64
			
		if is_instance_of(body, CharacterBody2D):
			
			if lastDir == 1:
				body.scale = global_scale
				body.rotation_degrees = global_rotation_degrees
			body.carried = true
			body.set_physics_process(false)
			body.collision_layer = 8
			body.collision_mask = 0
		checkIfBuildAllowed()

func drown():
	if carrying and carrySlot.get_child_count() > 0:
		letGo()
	visible = false
	var throwObject: Throwable = Data.throwable.instantiate()
	throwObject.overrideGravity = -0.025
	throwObject.temporary = false
	throwObject.sprite.frame = 27
	Data.emit_signal("sendRep", id, throwObject)
	throwObject.commit(self)
	throwObject.spawn = false
	get_tree().current_scene.call_deferred("add_child", throwObject)
	throwObject.position = global_position

var input = {
	"RIGHT" : false,
	"LEFT" : false,
	"INTERACT" : false,
	"AIM" : false,
	"DROP" : false,
	"JUMP" : false,
	"STRUGGLE" : false,
	"USE" : false
}

var statuses = {
	"ID" : -1,
	"ACCEPT" : true,
	"SELECTED" : false,
	"CARRYING" : false,
	"ON_GOAL" : false
}

func _input_process():
	if Data.controllers[id]: 
		statuses["ACCEPT"] = true
		return
	if isUsing:
		return
	statuses["ACCEPT"] = false
	var alt = [2, 1]
	input["INTERACT"] = Input.is_action_just_pressed("W%d" % id)
	input["AIM"] = Input.is_action_pressed("W%d" % id)
	input["DROP"] = Input.is_action_just_pressed("S%d" % id)
	input["JUMP"] = Input.is_action_just_pressed("Jump%d" % id)
	input["LEFT"] = Input.is_action_pressed("A%d" % id)
	input["RIGHT"] = Input.is_action_pressed("D%d" % id)
	input["STRUGGLE"] = Input.is_action_just_pressed("Jump%d" % alt[id - 1])
	input["USE"] = Input.is_action_just_pressed("UseItem%d" % id)
	

var waterGridCoordinates
var isCarryingBucket = false

func _draw():
	if not isCarryingBucket: return
	if len(waterGridCoordinates) == 0: return
	var x = (waterGridCoordinates[0].x * 16)
	var y = ((waterGridCoordinates[0].y - 2) * 16)
	
	var finalPos = to_local(waterHandler.fromWaterGridGlobal(Vector2(x, y)))
	var rect: Rect2
	var size
	var sizeY
	if is_instance_valid(bucket) and not activeInteractible:
		if bucket.filled:
			size = 16
			sizeY = 16
		else:
			size = 32
			sizeY = 48
	else:
		return
	
	
	if lastDir > 0:
		rect = Rect2(finalPos.x, finalPos.y + 1, size, sizeY)
	else:
		rect = Rect2(finalPos.x + 16, finalPos.y + 1, -size, sizeY)
	draw_rect(rect, Color.NAVY_BLUE, false)

var bucket: Bucket
var bucketActionCells: Array[Vector2]

func carryBucket(value: bool, bucketObject = null):
	if is_instance_valid(bucketObject) and is_instance_of(bucketObject, Bucket):
		if value:
			bucket = bucketObject
		else:
			bucket = null

func bucketProcess(delta: float):
	if carrySlot.get_child_count() > 0 and is_instance_of(carrySlot.get_child(0), Bucket):
		isCarryingBucket = true
		waterGridCoordinates = waterHandler.getCoordinateFromPosition(global_position)
		waterGridCoordinates.y += 2
		waterGridCoordinates = bucket.getTargetCell(waterGridCoordinates, lastDir)
		queue_redraw()
		
		var animName = "useBucket"
		if lastDir < 0: animName += "Flip"
		
		if input["USE"] and not activeInteractible:
			if not bucket.filled:
				if len(waterGridCoordinates) > 0:
					
					isUsing = true
					playerAnim.play(animName)
					await get_tree().create_timer(0.25).timeout
					
					for cell in waterGridCoordinates:
						bucket.amountHeld += waterHandler.takeWater(cell.x, cell.y)
					if bucket.amountHeld >= 0.5:
						bucket.fill(true)
					await get_tree().create_timer(0.25).timeout
					isUsing = false
			elif bucket.filled:
				if len(waterGridCoordinates) > 0: 
					if bucket.amountHeld >= 0.5:
						isUsing = true
						playerAnim.play(animName)
						await get_tree().create_timer(0.25).timeout
						bucket.fill(false)
						for cell in waterGridCoordinates:
							waterHandler.addWater(cell.x, cell.y, bucket.amountHeld)
							bucket.amountHeld = 0
						await get_tree().create_timer(0.25).timeout
						isUsing = false
				
					
		elif input["USE"] and activeInteractible:
			activeInteractible.interact()
			activeInteractible.showHighlight(false)
			isUsing = true
			playerAnim.play(animName)
			await get_tree().create_timer(0.25).timeout
			bucket.amountHeld = 0
			bucket.fill(false)
			await get_tree().create_timer(0.25).timeout
			isUsing = false
			
	else: 
		isCarryingBucket = false
		queue_redraw()
	
var isUsing: bool = false

func _process(delta: float) -> void:
	_input_process()
	
	if not isUsing:
		bucketProcess(delta)
	
	if breathBar.visible and breath == remainingBreath:
		breathBar.visible = false
		
	elif not breathBar.visible and remainingBreath < breath:
		breathBar.visible = true
		barAnim.play("RESET")
	highlight.frame = sprite.frame
	cdTimer = move_toward(cdTimer, 0, delta)
	pickupTimer = move_toward(pickupTimer, 0, delta)
	
	if submerged:
		breathBar.get_child(0).scale.x = remainingBreath/breath
		remainingBreath = move_toward(remainingBreath, 0, delta)
		if remainingBreath == 0 and not dead:
			dead = true
			drown()

	else:
		breathBar.get_child(0).scale.x = remainingBreath/breath
		remainingBreath = move_toward(remainingBreath, breath, delta * 3)
	
	if not Data.allowInput:
		return
	if Input.is_action_just_pressed("Reset"):
		Data.emit_signal("levelEnd", Data.activeLevel)
		FireSfx.clearSFX()
		return
	if Input.is_action_just_pressed("Return"):
		Data.emit_signal("levelEnd", -1)
		FireSfx.clearSFX()
		Bgm.stop()
		return
	
	if input["INTERACT"] and selected and len(carrySlot.get_children()) == 0 and not carried:
		if is_instance_of(selected, Player1):
			if not selected.carrying:
				carry()
		else:
			carry()
	elif (input["DROP"]) and len(carrySlot.get_children()) > 0 and goal and stack():
		pass
	elif input["DROP"] and len(carrySlot.get_children()) > 0:
		letGo()
	elif input["STRUGGLE"] and len(carrySlot.get_children()) > 0 and is_instance_of(carrySlot.get_child(0), Player1):
		letGo()

	
	if is_instance_valid(selected):
		if is_instance_of(selected, Liftable) and not carrying and not carried and selected.liftable:
			selected.highlight.visible = true
		
	if is_instance_valid(selected) and is_instance_of(selected, Player1) and not carrying and not carried:
		if not selected.carrying:
			selected.highlight.visible = true

	
	if carried or carrying:
		highlight.visible = false
		
var pingInterval: int = 100 # frames
var ping = 0
func _physics_process(delta: float) -> void:
	if ping < pingInterval:
		ping += 1
	else:
		ping = 0
		get_parent().broadcastState(statuses)
	if not throwAnim and aiming or (input["INTERACT"] and len(carrySlot.get_children()) > 0):
		if not (throwAnim or len(carrySlot.get_children()) == 0 or cdTimer > 0):
			
			aimAssist.visible = true
			aiming = true
			if input["AIM"]:
				aim(delta)
			else:
				aiming = false
				throw(angle)
	if is_on_floor():
		mercyJumpTimer = mercyJump
	else:
		mercyJumpTimer = move_toward(mercyJumpTimer, 0, delta)
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		if waded:
			if velocity.y > 10:
				velocity.y = lerp(velocity.y, 10.0, 10 * delta)
			else:
				velocity.y = lerp(velocity.y, 10.0, 6 * delta)
	
	# Handle jump.
	var jumpFrame: bool
	bufferTimer = move_toward(bufferTimer, 0, delta)
	if input["JUMP"] and Data.allowInput:
		bufferTimer = jumpBuffer
	
	if bufferTimer > 0 and mercyJumpTimer > 0:
		jumpFrame = true
		if carrying:
			if not waded:
				velocity.y = -180
			else:
				velocity.y = -144
			
		else:
			velocity.y = JUMP_VELOCITY
		mercyJumpTimer = 0
		bufferTimer = 0

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = (-int(input["LEFT"])) + int(input["RIGHT"])  #(Input.get_axis("A%d" % id, "D%d" % id))
	
	if direction and Data.allowInput and not isUsing:
		#anime.play("walk", -1, 1.5)
		velocity.x = direction * SPEED
		if is_on_floor():
			if not jumpFrame:
				velocity.y = HOP_VELOCITY
			if not carrying and not throwAnim:
				
				if sprite.frame in [8, 0]:
					sprite.frame = 6
				else:
					sprite.frame = 8
			elif not throwAnim:
				if sprite.frame in [13, 19]:
					sprite.frame = 21
				else:
					sprite.frame = 19
			
	else:
		if not throwAnim and not isUsing:
			if not carrying:
				sprite.frame = 0
			else:
				sprite.frame = 13
		#anime.play("RESET")
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if direction > 0:
		lastDir = 1
		#scale.y = 1
		#rotation_degrees = 0
		sprite.flip_h = false
		pickup.scale.y = 1
		pickup.rotation_degrees = 0
		build.scale.y = 1
		build.rotation_degrees = 0
		
		interact.scale.y = 1
		interact.rotation_degrees = 0
		
		bubbles.scale.y = 1
		bubbles.rotation_degrees = 0
		
		torchCatch.scale.y = 1
		torchCatch.rotation_degrees = 0
		
	elif direction < 0 :
		lastDir = -1
		#rotation_degrees = 180
		#scale.y = -1
		sprite.flip_h = true
		pickup.scale.y = -1
		pickup.rotation_degrees = 180
		build.scale.y = -1
		build.rotation_degrees = 180
		
		bubbles.scale.y = -1
		bubbles.rotation_degrees = 180
		
		interact.scale.y = -1
		interact.rotation_degrees = 180
		
		torchCatch.scale.y = -1
		torchCatch.rotation_degrees = 180
		
	
	move_and_slide()

var selectionQueue: Array

func onPickUpEntered(body: Node2D) -> void:
	if is_instance_of(body, Liftable) and not body.liftable:
		return
	if selected:
		selectionQueue.append(body)
		return
	
	selected = body
	statuses["SELECTED"] = true
	if not carried:
		get_parent().broadcastState(statuses)
		

func onPickUpExited(body: Node2D) -> void:
	if is_instance_of(selected, Liftable):
		selected.highlight.visible = false
	if is_instance_of(selected, Player1):
		selected.highlight.visible = false
	
	selectionQueue.erase(body)
	if len(selectionQueue) > 0:
		selected = selectionQueue[0]
		
		
	else:
		selected = null
		if not carried and not carrying:
			statuses["SELECTED"] = false
			get_parent().broadcastState(statuses)
			#print(self.name, " ", statuses)
			



func onBuildEntered(body: Node2D) -> void:
	if carrySlot.get_child_count() == 0: return
	var carryThing = carrySlot.get_child(0)
	goal = body
	onBuild = true
	if carrying and not carried and is_instance_of(carryThing, Liftable) and goal.requests[0] == carryThing.id:
		statuses["ON_GOAL"] = true
		get_parent().broadcastState(statuses)
		
func checkIfBuildAllowed():
	var buildScan = $Build
	buildScan.monitoring = false
	buildScan.set_deferred("monitoring", true)


func onBuildExited(body: Node2D) -> void:
	goal = null
	if not carried:
		statuses["ON_GOAL"] = false
		get_parent().broadcastState(statuses)
	onBuild = false
	

func checkCarry():
	if carrySlot.get_child_count() == 0:
		return
	var body = carrySlot.get_child(0)
	if is_instance_of(body, Liftable):
		if not body.liftable:
			letGo()


func torchEntered(body: Node2D) -> void:
	if is_instance_of(body, Torch) and body.isBeingThrown and pickupTimer == 0:
		if selected:
			selected.highlight.visible = false
	
		selected = body

var activeInteractible

func onInteractEntered(area: Area2D) -> void:
	
	var interactible = area.get_parent()
	
	activeInteractible = interactible
	
	if is_instance_of(activeInteractible, Gabi) and is_instance_valid(bucket) and bucket.filled and activeInteractible.interactionAllowed:
		pass
	else:
		activeInteractible = null
		return
	interactible.showHighlight(true)


func onInteractExited(area: Area2D) -> void:
	if is_instance_valid(activeInteractible):
		activeInteractible.showHighlight(false)
		activeInteractible = null
	
