extends StaticBody2D

class_name Burnable

var burnables: Array

var sprite: Sprite2D
@export var frameOverride: int = -1
@export var grouped: bool = true
@export var destroyImmediately: bool = false
@export var durability: float = 0.3
var dur = 0
@export var burnForce: float = 120
var particles: Array[CPUParticles2D]
@export var smokeParticles: CPUParticles2D
@export var deathParticles: CPUParticles2D
var burnTime: float = 0
@export var isBurning: bool = false
var initialGradient: Gradient
var initialAmount: int
var initialTime: float
var originalAmount = [0, 0]
var groupHandler: BurnGroup
var burnt: bool = false

func overrideBurnVisuals(override: bool):
	smokeParticles.emitting = override
	for p in particles:
		p.emitting = override

func applyBurnChanges():
	if isBurning:
		FireSfx.increaseFlame()
		var i = 0
		for p in particles:
			p.emitting = isBurning
			await TimeUtil.wait(durability/3)
		smokeParticles.emitting = isBurning
	else:
		for p in particles:
			p.emitting = false
		smokeParticles.emitting = false

func burn(delta: float):
	if not isBurning:
		dur = durability
		applyBurnChanges()
		return
	
	if burnTime == 0:
		applyBurnChanges()
	burnTime += delta
	dur = move_toward(dur, 0, delta)
		
	if dur <= 0:
		
		for b in burnables:
			b.isBurning = true
		burnables.clear()
		if not grouped and not burnt:
			burnt = true
			if not destroyImmediately:
				await TimeUtil.wait(durability)
			destroy()
		if grouped and not burnt:
			burnt = true
			if not destroyImmediately:
				await TimeUtil.wait(durability)
			groupHandler.attemptDestroy()

		

func destroy():
	FireSfx.decreaseFlame()
	sprite.visible = false
	isBurning = false
	overrideBurnVisuals(false)
	deathParticles.restart()
	collision_layer = 0
	collision_mask = 0

func _ready() -> void:
	if grouped:
		groupHandler = get_parent()
	sprite = get_node("Sprite2D")
	if frameOverride >= 0:
		sprite.frame = frameOverride
	
	
	for i in range(2):
		particles.append(get_node("burnParticles%d" % (i + 1)))
	initialGradient = particles[0].color_ramp
	initialAmount = particles[0].amount
	initialTime = particles[0].lifetime
	originalAmount[0] = particles[0].amount
	originalAmount[1] = particles[1].amount

@export var debug: bool
func _process(delta: float) -> void:
	burn(delta)
	sprite.self_modulate = lerp(Color.WHITE, Color(0.2, 0.2, 0.2), 1 - (dur/durability))


func bodyEntered(body: Node2D) -> void:
	if is_instance_of(body, Burnable) or is_instance_of(body, Liftable) and not body.isBurning:
		burnables.append(body)


func bodyExited(body: Node2D) -> void:
	burnables.erase(body)
