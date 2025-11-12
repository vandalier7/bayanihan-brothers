extends RigidBody2D

class_name Liftable

@export var id: int
@export var top: Node2D
@export var highlight: Sprite2D
@export var burnHighlight: Sprite2D
var sprite: Sprite2D
var originalLayer
var originalMask
@export var floats: bool = true
var liftable: bool = true
@export var flammable: bool = true
@export var important: bool = true

@export var durability: float = 5.0
var dur = 0
@export var interval: float = 1.0
@export var burnForce: float = 120
var particles: Array[CPUParticles2D]
@export var smokeParticles: CPUParticles2D
@export var douseParticles: CPUParticles2D
@export var deathParticles: CPUParticles2D
@export var putOut: Gradient
@export var splash: CPUParticles2D
var burnTime: float = 0
@export var isBurning: bool = false
@export var volume: float = 0
var initialGradient: Gradient
var initialAmount: int
var initialTime: float
var originalAmount = [0, 0]
var depthEntry: float = -9999
var customDepth: bool = false
var surfaceLevel: float = 0

var playersOnMe: int = 0

var collider: CollisionShape2D

func depthOverride(boolean: bool, value: float = 0):
	customDepth = boolean
	depthEntry = value

func overrideBurnVisuals(override: bool):
	smokeParticles.emitting = override
	for p in particles:
		p.emitting = override

func applyBurnChanges():
	burnHighlight.visible = isBurning
	if isBurning:
		if dur < durability * 0.333:
			smokeParticles.emitting = true
		if dur < durability * 0.667:
			particles[1].emitting = true
		particles[0].emitting = true
	else:
		for p in particles:
			p.emitting = false
		smokeParticles.emitting = false

func douse():
	isBurning = false
	douseParticles.restart()
	FireSfx.decreaseFlame()
	Data.emit_signal("playAudio", Data.steam)

func burn(delta: float):
	if not isBurning:
		dur = durability
		applyBurnChanges()
		return
	
	if dur == durability:
		FireSfx.increaseFlame()
		burnTime = 0
	
	if burnTime == 0:
		if round(linear_velocity.y) == 0:
			var v = (Vector2.UP * burnForce) + Vector2(randi_range(-50, 50), 0)
			apply_impulse(v)
	applyBurnChanges()
	burnTime += delta
	
	
	
	dur -= delta
	if burnTime > interval:
		burnTime = 0
		
	if dur <= 0:
		if important:
			Data.emit_signal("levelEnd", Data.activeLevel, true)
		FireSfx.decreaseFlame()
		sprite.visible = false
		highlight.visible = false
		burnHighlight.visible = false
		liftable = false
		isBurning = false
		Data.emit_signal("checkCarries")
		overrideBurnVisuals(false)
		deathParticles.restart()
		collision_layer = 0
		collision_mask = 0
		freeze = true
		await TimeUtil.wait(2)
		queue_free()

func _ready() -> void:
	sprite = get_node("Sprite2D")
	originalLayer = collision_layer
	originalMask = collision_mask
	for i in range(get_child_count()):
		if is_instance_of(get_child(i), CollisionShape2D):
			collider = get_child(i)
			break
	assert(is_instance_valid(collider), "Collider not found")
		
	for i in range(2):
		particles.append(get_node("burnParticles%d" % (i + 1)))
	initialGradient = particles[0].color_ramp
	initialAmount = particles[0].amount
	initialTime = particles[0].lifetime
	originalAmount[0] = particles[0].amount
	originalAmount[1] = particles[1].amount

func allowPlayerInteractionForThisFrame(value):
	if value:
		collision_layer = originalLayer + 3
		collision_mask = originalLayer - 125
		#collider.one_way_collision = true
	else:
		collision_layer = originalLayer
		collision_mask = originalMask
		#collider.one_way_collision = false
		

func _process(delta: float) -> void:
	burn(delta)
	
