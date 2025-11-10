extends Node

class_name GrassGrouper

@export_range(1, 20) var sway_amplitude: float = 10.0  # max sway variation in degrees
@export_range(1, 5) var wind_speed: float = 2.0      # how fast the blades sway
@export_range(-50, 50) var wind_direction: float = 0.0  # base tilt angle (negative = left, positive = right)
@export var pushback_strength: float = 35.0  # how far to push back
@export var pushback_duration: float = 0.3  # how long the pushback lasts
@export_range(0, 1) var flowerChance: float = 0.05  
