extends CharacterBody2D

class_name Player2

var selected: PhysicsBody2D
var lastDir: int
var originalLayer
var originalMask
var carried:= false

@export var id: int = 1
@export var mercyJump: float = 0.1
var mercyJumpTimer: float = 0
const SPEED = 120.0
const JUMP_VELOCITY = -250.0
const HOP_VELOCITY = -60

var sprite: Sprite2D
var anime: AnimationPlayer
var carrySlot: Node2D
var drop: Node2D

func _ready() -> void:
	sprite = get_node("Sprite2D")
	anime = get_node("AnimationPlayer")
	carrySlot = get_node("Slot")
	drop = get_node("Drop")
	originalLayer = collision_layer
	originalMask = collision_mask

func letGo():
		var body: PhysicsBody2D = carrySlot.get_child(0)
		body.get_parent().remove_child(body)
		
		body.position = carrySlot.global_position
		
		if is_instance_of(body, RigidBody2D):
			get_tree().current_scene.add_child(body)
			body.freeze = false
			body.collision_layer = body.originalLayer
			body.collision_mask = body.originalMask
			body.linear_velocity = Vector2(lastDir * 100, -100)
		if is_instance_of(body, CharacterBody2D):
			body.carried = false
			var throwObject: Throwable = Data.throwable.instantiate()
			if lastDir == -1:
				throwObject.sprite.flip_h = true
			throwObject.commit(body)
			
			#throwObject.sprite.texture = Data.throwSprite
			get_tree().current_scene.add_child(throwObject)
			throwObject.position = carrySlot.global_position
			
			
			#body.velocity = velocity
			
			throwObject.linear_velocity = Vector2(lastDir * 100, -100)

func carry():
		var body: PhysicsBody2D = selected
		selected.get_parent().remove_child(body)
		body.position = Vector2(0, 0)
		
		
		carrySlot.add_child(body)
		if is_instance_of(body, RigidBody2D):
			body.freeze = true
			body.collision_layer = 132
			body.collision_mask = 128
			
		if is_instance_of(body, CharacterBody2D):
			body.carried = true
			body.set_physics_process(false)
			body.collision_layer = 8
			body.collision_mask = 0

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("W%d" % id) and selected and len(carrySlot.get_children()) == 0 and not carried:
		carry()
	elif Input.is_action_just_pressed("S%d" % id) and len(carrySlot.get_children()) > 0:
		letGo()

func _physics_process(delta: float) -> void:
	if is_on_floor():
		mercyJumpTimer = mercyJump
	else:
		mercyJumpTimer = move_toward(mercyJumpTimer, 0, delta)
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("Jump%d" % id) and mercyJumpTimer > 0:
		velocity.y = JUMP_VELOCITY
		mercyJumpTimer = 0

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("A%d" % id, "D%d" % id)
	
	if direction:
		#anime.play("walk", -1, 1.5)
		velocity.x = direction * SPEED
		if is_on_floor():
			
			velocity.y = HOP_VELOCITY
			if sprite.frame in [8, 0]:
				sprite.frame = 6
			else:
				sprite.frame = 8
			
	else:
		sprite.frame = 0
		#anime.play("RESET")
		velocity.x = move_toward(velocity.x, 0, SPEED)
	if direction > 0:
		lastDir = 1
		scale.y = 1
		rotation_degrees = 0
	elif direction < 0 :
		lastDir = -1
		rotation_degrees = 180
		scale.y = -1
		
	
	move_and_slide()


func onPickUpEntered(body: Node2D) -> void:
	selected = body


func onPickUpExited(body: Node2D) -> void:
	selected = null
