extends Node2D

@export var initialAmount: int = 12
@export var radius: float = 30.0
@export var gravity: float = 980
@export var stiffness: float = 80.0
@export var center_stiffness: float = 100.0
@export var damping: float = 5.0
@export_range(0, 1) var collisionDamping: float = 0.3
@export var shapeRestoringStrength: float = 50.0
@export var show_outline: bool = true

var points = []
var velocities = []
var forces = []
var springs = []  # Each spring is [a, b, rest_len, stiffness]
var original_offsets = []

var center = Vector2()
var center_velocity = Vector2.ZERO
var center_force = Vector2.ZERO

func _ready() -> void:
	var origin = Vector2(200, 100)
	center = origin
	
	points.clear()
	velocities.clear()
	forces.clear()
	springs.clear()
	original_offsets.clear()
	
	# Place points in circle
	for i in initialAmount:
		var angle = TAU * i / initialAmount
		var point = center + Vector2(radius * cos(angle), radius * sin(angle))
		points.append(point)
		original_offsets.append(point - center)
		velocities.append(Vector2.ZERO)
		forces.append(Vector2.ZERO)

	# Outer ring springs
	for i in initialAmount:
		var a = i
		var b = (i + 1) % initialAmount
		var rest_len = (points[a] - points[b]).length()
		springs.append([a, b, rest_len, stiffness])

	# Springs to center
	for i in initialAmount:
		var rest_len = (points[i] - center).length()
		springs.append([i, -1, rest_len, center_stiffness])

func _draw():
	if show_outline:
		draw_colored_polygon(PackedVector2Array(points), Color.CORNFLOWER_BLUE.darkened(0.2))
	for s in springs:
		var a = points[s[0]]
		var b = center if (s[1] == -1) else points[s[1]]
		# Uncomment to see springs
		# draw_line(a, b, Color.LIGHT_BLUE, 0.5)
	for p in points:
		draw_circle(p, 2, Color.BLUE)
	draw_circle(center, 3, Color.RED)

func apply_spring_force(a: int, b: int, rest_len: float, k: float):
	var pa = points[a]
	var va = velocities[a]
	var pb = center if b == -1 else points[b]
	var vb = center_velocity if b == -1 else velocities[b]

	var delta = pb - pa
	var dist = delta.length()
	if dist == 0:
		return
	var dir = delta / dist
	var rel_vel = vb - va

	var spring_force = dir * (k * (dist - rest_len))
	var damp_force = dir * (rel_vel.dot(dir)) * damping
	var total_force = spring_force + damp_force

	forces[a] += total_force
	if b == -1:
		center_force -= total_force
	else:
		forces[b] -= total_force

func _physics_process(delta: float) -> void:
	# Reset forces
	for i in points.size():
		forces[i] = Vector2(0, gravity)
		var target = center + original_offsets[i]
		forces[i] += (target - points[i]) * shapeRestoringStrength
	center_force = Vector2(0, gravity)

	# Apply spring forces
	for spring in springs:
		apply_spring_force(spring[0], spring[1], spring[2], spring[3])

	# Update motion
	for i in points.size():
		velocities[i] += forces[i] * delta
		points[i] += velocities[i] * delta
		
		if points[i].y > 300:
			points[i].y = 300
			velocities[i].y = -velocities[i].y * (1 - collisionDamping)

	center_velocity += center_force * delta
	center += center_velocity * delta
	if center.y > 300:
		center.y = 300
		center_velocity.y = -center_velocity.y * (1 - collisionDamping)

	queue_redraw()
