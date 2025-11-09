extends Liftable

class_name Torch
var isBeingThrown: bool = false
var explosionParticles: Array[CPUParticles2D]
var burnables: Array
var players: Array
@export var torchParticle: CPUParticles2D
@export var animator: AnimationPlayer
@export var knockback: int = 200
@export var startingCharges: int = 3
var chargeDisplay
var charges = []
var slots = []

var remainingCharges: int

func _ready() -> void:
	remainingCharges = startingCharges
	super._ready()
	flammable = false
	chargeDisplay = $ChargeDisplay
	for i in range(3):
		charges.append(get_node("ChargeDisplay/%d" % (i+1)))
		slots.append(get_node("ChargeDisplay/Holder%d" % (i + 1)))
	for i in range(2):
		explosionParticles.append(get_node("explosion%d" % (i+1)))
	for i in range(startingCharges):
		charges[i].visible = true
		slots[i].visible = true

func setThrown():
	chargeDisplay.visible = false
	isBeingThrown = true
	#collision_layer = 0
	#collision_mask = 0
	
	animator.play("throw", -1, 4)

func setCarry():
	for i in range(3):
		if i < remainingCharges:
			charges[i].visible = true
		else:
			charges[i].visible = false
	chargeDisplay.visible = true
	animator.play("carry")
	highlight.visible = false
	isBeingThrown = false
	sprite.frame = 1

func setStanding():
	#collision_layer = 1024 + 2048 + 512
	#collision_mask = 512
	chargeDisplay.visible = false
	animator.play("RESET")

func onTrigger(body: Node2D) -> void:
	if isBeingThrown:
		Data.emit_signal("playAudio", Data.erupt)
		remainingCharges -= 1
		liftable = false
		torchParticle.emitting = false
		isBeingThrown = false
		for p in explosionParticles:
			p.restart()
		for b in burnables:
			b.isBurning = true
		
		for p: Player1 in players:
			var direction = (-global_position + p.global_position).normalized()
			var distance = min(36, global_position.distance_to(p.global_position))
			var force = direction * knockback * (1.8 - (distance/36))
			p.substitute(Vector2(force))
		
		if remainingCharges > 0:
			setStanding()

			linear_velocity = Vector2(0, -knockback)
			await get_tree().create_timer(1.5).timeout
			liftable = true
			torchParticle.emitting = true
		else:
			$Flame.collision_layer = 0
			collision_layer = 0
			sprite.visible = false
			highlight.visible = false
			await get_tree().create_timer(3).timeout
			queue_free()


func onBodyEntered(body: Node2D) -> void:
	if not isBeingThrown:
		return
	if is_instance_of(body, Liftable) and body.flammable:
		burnables.append(body)
	if is_instance_of(body, Burnable):
		burnables.append(body)
	if is_instance_of(body, Player1):
		players.append(body)


func onBodyExited(body: Node2D) -> void:
	burnables.erase(body)
	players.erase(body)

func douse():
	Data.emit_signal("playAudio", Data.steam)
	liftable = false
	
	set_deferred("freeze", true)
	deathParticles.restart()
	sprite.visible = false
	highlight.visible = false
	torchParticle.emitting = false
	Data.emit_signal("checkCarries")
	await TimeUtil.wait(3)
	queue_free()
