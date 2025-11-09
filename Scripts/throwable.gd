extends RigidBody2D

class_name Throwable

var lock = false
var spawn = true
var collisionShape: CollisionShape2D
var bodyData: Player1
@export var sprite: Sprite2D
@export var slot: Node2D
@export var highlight: Sprite2D
@export var submergedDamp: float = 2
@export var volume: float = 3.0
var maxBreath: float
var breath: float

var submerged: bool = false
var waded: bool = false
var temporary: bool = true

var overrideGravity: float = 0
var breathBar: Node2D

var splash: CPUParticles2D

var dead: bool
var barAnim: AnimationPlayer
func _ready() -> void:
	breathBar = $Breath
	barAnim = $BarAnim
	splash = $Splash
	barAnim.play("RESET")

func _physics_process(delta: float) -> void:
	if waded:
		if linear_velocity.y > 10:
			linear_velocity.y = lerp(linear_velocity.y, 10.0, 10 * delta)


func _process(delta: float) -> void:
	if dead: return
	if breathBar.visible and breath == maxBreath:
		breathBar.visible = false
	elif not breathBar.visible and breath < maxBreath:
		breathBar.visible = true
		barAnim.play("RESET")
	
	if submerged:
		breathBar.get_child(0).scale.x = breath/maxBreath
		breath = move_toward(breath, 0, delta)
		if breath == 0 and not dead:
			breathBar.visible = false
			gravity_scale = -0.025
			dead = true
			sprite.frame = 27
			temporary = false
			Data.emit_signal("playAudio", Data.drown)
			await TimeUtil.wait(1.3)
			Data.emit_signal("levelEnd", Data.activeLevel, true)
			
	else:
		breathBar.get_child(0).scale.x = breath/maxBreath
		breath = move_toward(breath, maxBreath, delta * 3)

func submerge(value: bool):
	submerged = value
	breathBar.visible = value
	if not submerged:
		barAnim.pause()
	
	if overrideGravity != 0:
		gravity_scale = overrideGravity

func wade(value: bool):
	waded = value
	if waded:
		linear_damp = submergedDamp
		gravity_scale = 0.5
	else:
		linear_damp = 0
		gravity_scale = 1

func commit(character: Player1):
	bodyData = character
	maxBreath = character.breath
	breath = character.remainingBreath
	sprite.texture = bodyData.sprite.texture
	if len(bodyData.carrySlot.get_children()) > 0:
		var body = bodyData.carrySlot.get_child(0).duplicate()
		slot.add_child(body)
		if is_instance_of(body, RigidBody2D):
			body.freeze = true
			body.collision_layer = 132
			body.collision_mask = 128
		
func bodyEntered(body: Node2D) -> void:
	collide()
	
func collide():
	if not temporary:
		sprite.frame = 27
		return
	
	if not lock:
		lock = true
		sprite.frame = 27
		
		await get_tree().create_timer(1).timeout
		bodyData.position = global_position
		bodyData.repped = false
		bodyData.set_physics_process(true)
		bodyData.collision_layer = bodyData.originalLayer
		bodyData.collision_mask = bodyData.originalMask
		bodyData.remainingBreath = breath
		self.visible = false
		if get_tree().current_scene and spawn:
			get_tree().current_scene.add_child(bodyData)
		if not spawn:
			bodyData.visible = true
		
		self.freeze = true
		await TimeUtil.wait(4)
		queue_free()
