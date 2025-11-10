extends Node2D

var sway_amplitude: float = 10.0  # max sway variation in degrees
var wind_speed: float = 2.0      # how fast the blades sway
var wind_direction: float = 0.0  # base tilt angle (negative = left, positive = right)
var pushback_strength: float = 35.0  # how far to push back
var pushback_duration: float = 0.3  # how long the pushback lasts


var blades = []
var blade_offsets = []  # stores a random phase offset per blade
var time = 0.0

var is_pushed_back = false
var pushback_time = 0.0

func _ready() -> void:
	var group: GrassGrouper = get_parent()
	sway_amplitude = group.sway_amplitude
	wind_direction = group.wind_direction
	wind_speed = group.wind_speed
	pushback_duration = group.pushback_duration
	pushback_strength = group.pushback_strength
	
	
	blades = get_children()
	blades.shuffle()
	# assign frame & z_index like before
	var i = 0
	var flip = false
	for blade in blades.duplicate():
		if not is_instance_of(blade, Sprite2D): 
			blades.erase(blade)
			continue
		blade.frame = i
		i += 1
		if flip:
			blade.z_index = -3
		flip = not flip
		# assign random phase for sine wave to offset blades individually
		blade_offsets.append(randf() * TAU)

func _process(delta: float) -> void:
	time += delta
	
	# Calculate wind influence (reduces pushback effectiveness)
	var wind_influence = abs(wind_direction) / 20.0  # normalize wind strength
	var effective_pushback = pushback_strength * (1.0 - clamp(wind_influence, 0.0, 0.8))
	
	if is_pushed_back:
		pushback_time += delta
		# Calculate how much to blend back to normal (0 = full pushback, 1 = normal)
		var blend = clamp(pushback_time / pushback_duration, 0.0, 1.0)
		
		for j in range(blades.size()):
			var blade = blades[j]
			var phase = blade_offsets[j]
			# normal sway rotation = wind direction + oscillation
			var normal_rotation = wind_direction + sin(time * wind_speed + phase) * sway_amplitude
			# pushed back rotation (opposite to wind direction)
			var pushed_rotation = -effective_pushback + wind_direction * 0.5
			# blend between the two
			blade.rotation_degrees = lerp(pushed_rotation, normal_rotation, blend)
		
		# end pushback after duration
		if blend >= 1.0:
			is_pushed_back = false
	else:
		# normal swaying with wind direction as base
		for j in range(blades.size()):
			var blade = blades[j]
			var phase = blade_offsets[j]
			# wind direction is the base angle, sway oscillates around it
			blade.rotation_degrees = wind_direction + sin(time * wind_speed + phase) * sway_amplitude

# Call this function to push blades back temporarily
func push_back() -> void:
	print("grass")
	is_pushed_back = true
	pushback_time = 0.0

func onBodyEntered(body: Node2D) -> void:
	push_back()
